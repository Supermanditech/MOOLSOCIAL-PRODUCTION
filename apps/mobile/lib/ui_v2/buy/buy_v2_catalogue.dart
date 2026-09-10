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

export '../../features/buy/buy_v2_content_contracts.dart'
    show BuyV2OfferPublisherType;

@immutable
class BuyV2PublishedOffer {
  const BuyV2PublishedOffer({
    required this.productId,
    required this.publisherType,
    required this.headline,
    this.publisherName,
    this.publicationId,
  });

  final String productId;
  final BuyV2OfferPublisherType publisherType;
  final String headline;
  final String? publisherName;
  final String? publicationId;

  String get identity =>
      publicationId ?? '${publisherType.name}:$productId:$headline';
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
    if (session.pagedOffersEnabled &&
        widget.source is BuyV2CataloguePublishedOffersSource) {
      return _PagedPublishedOffersView(session: session);
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
    final resolved = allResolved
        .where(
          (entry) =>
              session.finiteOffersCategoryId == 'all' ||
              entry.product.categoryId == session.finiteOffersCategoryId,
        )
        .toList(growable: false);
    final products = resolved
        .map((entry) => entry.product)
        .toList(growable: false);

    return BuyV2VerticalScrollIndicator(
      child: CustomScrollView(
        key: const PageStorageKey('buy-offers'),
        slivers: [
          SliverToBoxAdapter(
            child: _OffersCategoryControl(
              session: session,
              categoryId: session.finiteOffersCategoryId,
              onTap: () async {
                final selected = await _chooseOffersCategory(
                  context,
                  session,
                  session.finiteOffersCategoryId,
                );
                if (!mounted || selected == null) return;
                setState(() => session.finiteOffersCategoryId = selected);
              },
            ),
          ),
          if (resolved.isNotEmpty)
            SliverToBoxAdapter(
              child: _PublishedOfferPromotion(
                session: session,
                entries: resolved,
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
      ),
    );
  }
}

class _PagedPublishedOffersView extends StatefulWidget {
  const _PagedPublishedOffersView({required this.session});
  final BuyV2Session session;

  @override
  State<_PagedPublishedOffersView> createState() =>
      _PagedPublishedOffersViewState();
}

class _PagedPublishedOffersViewState extends State<_PagedPublishedOffersView> {
  static const _scope = 'published-offers';
  String _category = 'all';

  @override
  void initState() {
    super.initState();
    _restoreSelection();
  }

  void _restoreSelection() {
    final query = widget.session.retainedCatalogueOffersQuery(_scope);
    _category = query?.categoryId ?? 'all';
  }

  @override
  void didUpdateWidget(covariant _PagedPublishedOffersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) _restoreSelection();
  }

  Future<void> _chooseCategory() async {
    final selected = await _chooseOffersCategory(
      context,
      widget.session,
      _category,
    );
    if (!mounted || selected == null) return;
    setState(() => _category = selected);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return BuyV2PagedProductCatalogue(
      session: session,
      scopeKey: _scope,
      query: session.catalogueOffersQuery(categoryId: _category),
      publishedOffers: true,
      showAreaControl: true,
      controlsAfterProducts: true,
      header: _OffersCategoryControl(
        session: session,
        categoryId: _category,
        onTap: _chooseCategory,
      ),
      publicationFacts: (offers) => _PublishedOfferPromotion(
        session: session,
        entries: [
          for (final value in offers)
            (
              offer: BuyV2PublishedOffer(
                publicationId: value.publicationId,
                productId: value.product.id,
                publisherType: value.publisherType,
                headline: value.headline,
                publisherName: value.publisherName,
              ),
              product: value.product,
            ),
        ],
      ),
    );
  }
}

List<BuyV2Category> _offerCategories(BuyV2Session session) => {
  for (final destination in [BuyV2Destination.shop, BuyV2Destination.wholesale])
    for (final category in session.categoriesFor(destination))
      if (category.id != 'all') category.id: category,
}.values.toList(growable: false);

Future<String?> _chooseOffersCategory(
  BuildContext context,
  BuyV2Session session,
  String selected,
) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .8,
        child: BuyV2VerticalScrollIndicator(
          child: ListView(
            key: const ValueKey('buy-offers-category-list'),
            padding: EdgeInsets.fromLTRB(
              12,
              6,
              12,
              20 + BuyV2AddressSheetMotion.resolveBottomSafeInset(sheetContext),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Offer categories', style: context.buyTitle),
                  ),
                  IconButton(
                    tooltip: 'Close categories',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ListTile(
                key: const ValueKey('buy-offers-category-all'),
                title: const Text('All categories'),
                selected: selected == 'all',
                onTap: () => Navigator.pop(sheetContext, 'all'),
              ),
              for (final category in _offerCategories(session))
                ListTile(
                  key: ValueKey('buy-offers-category-${category.id}'),
                  title: Text(category.label),
                  selected: selected == category.id,
                  onTap: () => Navigator.pop(sheetContext, category.id),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OffersCategoryControl extends StatelessWidget {
  const _OffersCategoryControl({
    required this.session,
    required this.categoryId,
    required this.onTap,
  });
  final BuyV2Session session;
  final String categoryId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        _offerCategories(
          session,
        ).where((category) => category.id == categoryId).firstOrNull?.label ??
        'All categories';
    return BuyV2CartAvoidanceRegion(
      child: Padding(
        key: const ValueKey('buy-offers-publisher-summary'),
        padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Offers',
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
            ),
            _CatalogueChromeAction(
              key: const ValueKey('buy-offers-category-control'),
              label: 'Choose offer category. Current category $label',
              tooltip: 'Offer categories · $label',
              icon: Icons.grid_view_rounded,
              emphasized: true,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// Presentation of one source-owned offer and its exact product action.
/// Motion is finite on arrival/selection; it does not rotate while reading.
class _PublishedOfferPromotion extends StatefulWidget {
  const _PublishedOfferPromotion({
    required this.session,
    required this.entries,
  });
  final BuyV2Session session;
  final List<({BuyV2PublishedOffer offer, BuyV2Product product})> entries;

  @override
  State<_PublishedOfferPromotion> createState() =>
      _PublishedOfferPromotionState();
}

class _PublishedOfferPromotionState extends State<_PublishedOfferPromotion> {
  int get _index {
    final retained = widget.entries.indexWhere(
      (entry) =>
          entry.offer.identity == widget.session.featuredOfferPublicationId,
    );
    return retained < 0 ? 0 : retained;
  }

  void _select(int index) {
    setState(() {
      widget.session.featuredOfferPublicationId =
          widget.entries[index].offer.identity;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    final index = _index;
    final entry = widget.entries[index];
    final product = entry.product;
    final publisher =
        entry.offer.publisherName ??
        (entry.offer.publisherType == BuyV2OfferPublisherType.moolSocial
            ? 'MoolSocial'
            : product.seller);
    void open() {
      widget.session.featuredOfferPublicationId = entry.offer.identity;
      widget.session.openProduct(product.id);
    }

    return BuyV2CartAvoidanceRegion(
      child: Padding(
        key: const ValueKey('buy-published-offer-facts'),
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BuyV2Colors.softOrange, BuyV2Colors.softBlue],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33000080)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BuyV2FiniteIncomingTransition(
                  key: const ValueKey('buy-offer-promotion-motion'),
                  stateKey: '${entry.offer.identity}:${product.price}',
                  duration: const Duration(milliseconds: 450),
                  child: InkWell(
                    key: ValueKey('buy-published-offer-${product.id}'),
                    onTap: open,
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.offer.headline,
                          style: context.buyTitle.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.title,
                          style: context.buyBody.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Offer price ${buyV2Money(product.price)} · ${product.pack}',
                          style: context.buyBody.copyWith(
                            color: BuyV2Colors.green,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (product.minimumOrder > 1)
                          Text(
                            'Minimum ${product.minimumOrder} packs',
                            style: context.buyMeta,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Published by $publisher',
                          key: const ValueKey('buy-offer-promotion-publisher'),
                          style: context.buyMeta,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.entries.length > 1) ...[
                      IconButton(
                        key: const ValueKey('buy-offer-promotion-previous'),
                        tooltip: 'Previous offer',
                        onPressed: index > 0 ? () => _select(index - 1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        key: const ValueKey('buy-offer-promotion-next'),
                        tooltip: 'Next offer',
                        onPressed: index + 1 < widget.entries.length
                            ? () => _select(index + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                    const Spacer(),
                    Flexible(
                      flex: 3,
                      child: OutlinedButton(
                        key: ValueKey('buy-offer-promotion-cta-${product.id}'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: open,
                        child: const Text('View offer'),
                      ),
                    ),
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
    final loading =
        session.customerStateRestoring ||
        session.commerceLoadState == BuyV2CommerceLoadState.loading;
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

/// Bounded source pages rendered with the existing compact product cards.
class BuyV2PagedProductCatalogue extends StatefulWidget {
  const BuyV2PagedProductCatalogue({
    super.key,
    required this.session,
    required this.query,
    required this.scopeKey,
    this.header,
    this.onOpenProduct,
    this.storeContext = false,
    this.showAreaControl = false,
    this.usePrimaryScrollController = false,
    this.publishedOffers = false,
    this.publicationFacts,
    this.controlsAfterProducts = false,
  });

  final BuyV2Session session;
  final BuyV2CatalogueQuery query;
  final String scopeKey;
  final Widget? header;
  final ValueChanged<BuyV2Product>? onOpenProduct;
  final bool storeContext;
  final bool showAreaControl;
  final bool usePrimaryScrollController;
  final bool publishedOffers;
  final Widget Function(List<BuyV2PublishedCatalogueOffer>)? publicationFacts;
  final bool controlsAfterProducts;

  @override
  State<BuyV2PagedProductCatalogue> createState() =>
      _BuyV2PagedProductCatalogueState();
}

class _BuyV2PagedProductCatalogueState extends State<BuyV2PagedProductCatalogue>
    with WidgetsBindingObserver {
  late BuyV2CataloguePager<Object> _pager;
  late ScrollController _vertical;
  bool _ownsVertical = true;
  late List<ScrollController> _lanes;
  BuyV2CataloguePage<Object>? _shownPage;
  Timer? _publicationExpiry;
  bool _restoring = false;
  int _openSequence = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attach();
  }

  void _attach() {
    _pager = widget.publishedOffers
        ? widget.session.acquireCatalogueOffers(widget.scopeKey)
        : widget.session.acquireCatalogueProducts(widget.scopeKey);
    _shownPage = _pager.page;
    _vertical = ScrollController(
      initialScrollOffset: _pager.scrollOffset,
      keepScrollOffset: false,
    );
    _ownsVertical = true;
    _lanes = List.generate(
      2,
      (lane) => ScrollController(
        initialScrollOffset: _pager.laneOffset(lane),
        keepScrollOffset: false,
      ),
    );
    _vertical.addListener(_saveOffsets);
    for (final lane in _lanes) {
      lane.addListener(_saveOffsets);
    }
    _pager.addListener(_pageChanged);
    _scheduleQuery();
    _schedulePublicationExpiry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindPrimaryController();
  }

  void _bindPrimaryController() {
    final inherited = widget.usePrimaryScrollController
        ? PrimaryScrollController.maybeOf(context)
        : null;
    if ((inherited == null && _ownsVertical) ||
        identical(inherited, _vertical)) {
      return;
    }
    _saveOffsets();
    _vertical.removeListener(_saveOffsets);
    if (_ownsVertical) _vertical.dispose();
    _vertical =
        inherited ??
        ScrollController(
          initialScrollOffset: _pager.scrollOffset,
          keepScrollOffset: false,
        );
    _ownsVertical = inherited == null;
    _vertical.addListener(_saveOffsets);
  }

  void _saveOffsets() {
    if (_restoring ||
        _pager.query != widget.query ||
        _shownPage != _pager.page) {
      return;
    }
    if (_vertical.positions.length == 1) {
      _pager.scrollOffset = _vertical.offset.clamp(0.0, double.infinity);
    }
    for (var lane = 0; lane < _lanes.length; lane++) {
      if (_lanes[lane].hasClients) {
        _pager.rememberLaneOffset(
          lane,
          _lanes[lane].offset.clamp(0.0, double.infinity),
        );
      }
    }
  }

  void _scheduleQuery() {
    final sequence = ++_openSequence;
    Future<void>.microtask(() async {
      if (!mounted || sequence != _openSequence) return;
      if (_pager.query != widget.query ||
          (_pager.page == null && !_pager.loading && _pager.message == null)) {
        await _pager.open(widget.query);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BuyV2PagedProductCatalogue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.scopeKey != widget.scopeKey ||
        oldWidget.publishedOffers != widget.publishedOffers) {
      _detach(
        oldWidget.session,
        oldWidget.scopeKey,
        publishedOffers: oldWidget.publishedOffers,
      );
      _attach();
      _bindPrimaryController();
    } else if (oldWidget.query != widget.query) {
      _scheduleQuery();
    }
  }

  void _pageChanged() {
    if (!mounted) return;
    if (_shownPage != _pager.page) {
      _shownPage = _pager.page;
      _restoring = true;
      final page = _shownPage;
      final offset = _pager.scrollOffset;
      final lanes = List.generate(2, _pager.laneOffset);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || page != _pager.page) return;
        void restore(ScrollController controller, double value) {
          if (controller.positions.length == 1) {
            controller.jumpTo(
              value.clamp(0.0, controller.position.maxScrollExtent),
            );
          }
        }

        restore(_vertical, offset);
        for (var lane = 0; lane < _lanes.length; lane++) {
          restore(_lanes[lane], lanes[lane]);
        }
        _restoring = false;
      });
    }
    _schedulePublicationExpiry();
    setState(() {});
  }

  void _schedulePublicationExpiry() {
    _publicationExpiry?.cancel();
    if (!widget.publishedOffers) return;
    final now = widget.session.catalogueNow();
    Duration? earliest;
    for (final item in _pager.page?.items ?? const <Object>[]) {
      final offer = item as BuyV2PublishedCatalogueOffer;
      if (!offer.validUntil.isAfter(now)) continue;
      final remaining = offer.validUntil.difference(now);
      if (earliest == null || remaining < earliest) earliest = remaining;
    }
    if (earliest != null) {
      _publicationExpiry = Timer(earliest, () {
        if (!mounted) return;
        setState(() {});
        _schedulePublicationExpiry();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        !widget.publishedOffers ||
        !mounted) {
      return;
    }
    setState(() {});
    _schedulePublicationExpiry();
  }

  void _detach(
    BuyV2Session session,
    String scopeKey, {
    required bool publishedOffers,
  }) {
    _openSequence++;
    _publicationExpiry?.cancel();
    _saveOffsets();
    _pager.removeListener(_pageChanged);
    _vertical.removeListener(_saveOffsets);
    if (_ownsVertical) _vertical.dispose();
    for (final lane in _lanes) {
      lane.dispose();
    }
    if (publishedOffers) {
      session.releaseCatalogueOffers(scopeKey);
    } else {
      session.releaseCatalogueProducts(scopeKey);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detach(
      widget.session,
      widget.scopeKey,
      publishedOffers: widget.publishedOffers,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pager.query == widget.query ? _pager.page : null;
    final loading = _pager.query != widget.query || _pager.loading;
    final message = _pager.query == widget.query ? _pager.message : null;
    final offers = widget.publishedOffers
        ? page?.items.cast<BuyV2PublishedCatalogueOffer>().toList(
                growable: false,
              ) ??
              const <BuyV2PublishedCatalogueOffer>[]
        : const <BuyV2PublishedCatalogueOffer>[];
    final publicationCurrent =
        !widget.publishedOffers ||
        offers.every((offer) {
          final known = widget.session.findProduct(offer.product.id);
          return offer.isCurrent(now: widget.session.catalogueNow()) &&
              known != null &&
              known.storeId == offer.product.storeId &&
              known.destination == offer.product.destination &&
              known.price == offer.product.price &&
              known.pack == offer.product.pack;
        });
    final products = !publicationCurrent
        ? const <BuyV2Product>[]
        : widget.publishedOffers
        ? offers.map((offer) => offer.product).toList(growable: false)
        : page?.items.cast<BuyV2Product>().toList(growable: false) ??
              const <BuyV2Product>[];
    final needsArea =
        widget.query.storeId == null &&
        widget.query.areaScope != BuyV2CatalogueAreaScope.allAreas &&
        widget.query.regionId == null;
    final pageControls = _CataloguePageControls(
      scopeKey: widget.scopeKey,
      noun: widget.publishedOffers ? 'offers' : 'products',
      start: publicationCurrent ? page?.startIndex : null,
      count: products.length,
      total: publicationCurrent ? page?.totalCount : null,
      loading: loading,
      showRange: !widget.controlsAfterProducts,
      areaLabel: !widget.storeContext
          ? widget.session.catalogueAreaLabel
          : null,
      onArea: widget.showAreaControl
          ? () => showBuyV2CatalogueArea(context, widget.session)
          : null,
      onPrevious: !loading && publicationCurrent && page?.previousCursor != null
          ? _pager.previous
          : null,
      onNext: !loading && publicationCurrent && page?.nextCursor != null
          ? _pager.next
          : null,
      onRefresh: loading ? null : _pager.refresh,
    );
    return BuyV2VerticalScrollIndicator(
      child: ListView(
        key: ValueKey('buy-paged-scroll-${widget.scopeKey}'),
        controller: _vertical,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          if (widget.header != null) widget.header!,
          if (!widget.controlsAfterProducts) pageControls,
          if (loading && !widget.controlsAfterProducts)
            const LinearProgressIndicator(minHeight: 2),
          if (publicationCurrent &&
              offers.isNotEmpty &&
              widget.publicationFacts != null)
            widget.publicationFacts!(offers),
          if (needsArea)
            _CataloguePageNotice(
              title: 'Where are you shopping?',
              detail: 'Choose an area, or browse stores in any area.',
              action: 'Choose area',
              onAction: () => showBuyV2CatalogueArea(context, widget.session),
            )
          else if (!publicationCurrent)
            _CataloguePageNotice(
              title: 'Offers need refreshing',
              detail: 'The published details have changed or expired.',
              action: 'Refresh offers',
              onAction: loading ? null : _pager.refresh,
            )
          else if (message != null && !widget.controlsAfterProducts)
            _CataloguePageNotice(
              title: 'Results could not refresh',
              detail: message,
              action: 'Try again',
              onAction: _pager.retry,
            )
          else if (!loading && products.isEmpty && message == null)
            _CataloguePageNotice(
              title: widget.publishedOffers
                  ? 'No matching offers'
                  : 'No matching products',
              detail: 'Try another search, category or area.',
            ),
          if (products.isNotEmpty)
            _QuantityAwareGridLayout(
              session: widget.session,
              products: products,
              builder: (context, constraints, quantityWidth) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final layout = _resolveCompactProductGridLayout(
                  constraints: constraints,
                  accessibleText: scale > 1.25,
                  textScale: scale,
                  cartQuantityWidth: quantityWidth,
                  denseStore: widget.storeContext,
                  scrollIndicatorInset: true,
                );
                final laneCount = products.length == 1 ? 1 : 2;
                return SizedBox(
                  height:
                      layout.tileHeight * laneCount + (laneCount - 1) * 7 + 12,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (var lane = 0; lane < laneCount; lane++) ...[
                          if (lane > 0) const SizedBox(height: 7),
                          Expanded(
                            child: ListView.separated(
                              key: ValueKey(
                                'buy-paged-lane-${widget.scopeKey}-$lane',
                              ),
                              controller: _lanes[lane],
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              itemCount:
                                  (products.length - lane + laneCount - 1) ~/
                                  laneCount,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 7),
                              itemBuilder: (context, index) {
                                final product =
                                    products[index * laneCount + lane];
                                return SizedBox(
                                  width: layout.cardWidth,
                                  child: BuyV2ProductCard(
                                    key: ValueKey(
                                      'buy-paged-card-${product.id}',
                                    ),
                                    session: widget.session,
                                    product: product,
                                    compact: true,
                                    storeContext: widget.storeContext,
                                    onOpenProduct: widget.onOpenProduct,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          if (widget.controlsAfterProducts) ...[
            if (loading) const LinearProgressIndicator(minHeight: 2),
            if (!needsArea && publicationCurrent && message != null)
              _CataloguePageNotice(
                title: 'Results could not refresh',
                detail: message,
                action: 'Try again',
                onAction: _pager.retry,
              ),
            pageControls,
          ],
          if (!loading &&
              page != null &&
              products.isNotEmpty &&
              page.nextCursor == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'All matching ${widget.publishedOffers ? 'offers' : 'products'} are on this or earlier pages.',
                style: context.buyMeta,
              ),
            ),
        ],
      ),
    );
  }
}

String _catalogueCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (match) => '${match[1]},',
);

class _CataloguePageControls extends StatelessWidget {
  const _CataloguePageControls({
    required this.scopeKey,
    required this.start,
    required this.count,
    required this.total,
    required this.loading,
    this.areaLabel,
    this.onArea,
    this.onPrevious,
    this.onNext,
    this.onRefresh,
    this.noun = 'products',
    this.showRange = true,
  });
  final String scopeKey;
  final int? start;
  final int count;
  final int? total;
  final bool loading;
  final String? areaLabel;
  final VoidCallback? onArea;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onRefresh;
  final String noun;
  final bool showRange;

  @override
  Widget build(BuildContext context) {
    final range = start == null
        ? (loading
              ? 'Loading $noun'
              : '${noun[0].toUpperCase()}${noun.substring(1)}')
        : count == 0
        ? '0 $noun'
        : '${_catalogueCount(start! + 1)}–${_catalogueCount(start! + count)}'
              '${total == null ? '' : ' of ${_catalogueCount(total!)}'}'
              '${noun == 'products' ? '' : ' $noun'}';
    final rangeStyle = context.buyMeta.copyWith(fontWeight: FontWeight.w800);
    final summary = Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            range,
            key: ValueKey('buy-page-range-$scopeKey'),
            style: rangeStyle,
          ),
          if (areaLabel != null) Text(areaLabel!, style: context.buyMeta),
        ],
      ),
    );
    final previous = IconButton(
      key: ValueKey('buy-page-previous-$scopeKey'),
      tooltip: 'Previous $noun',
      onPressed: onPrevious,
      icon: const Icon(Icons.chevron_left_rounded),
    );
    final next = IconButton(
      key: ValueKey('buy-page-next-$scopeKey'),
      tooltip: 'Next $noun',
      onPressed: onNext,
      icon: const Icon(Icons.chevron_right_rounded),
    );
    final refresh = IconButton(
      key: ValueKey('buy-page-refresh-$scopeKey'),
      tooltip: 'Refresh $noun',
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded, size: 20),
    );
    final area = onArea == null
        ? null
        : IconButton(
            key: ValueKey('buy-page-area-$scopeKey'),
            tooltip: 'Choose shopping area',
            onPressed: onArea,
            icon: const Icon(Icons.location_on_outlined, size: 20),
          );
    if (!showRange) {
      return BuyV2CartAvoidanceRegion(
        key: ValueKey('buy-page-controls-protection-$scopeKey'),
        child: Semantics(
          key: ValueKey('buy-page-status-$scopeKey'),
          label: range,
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [previous, next, const Spacer(), refresh, ?area],
            ),
          ),
        ),
      );
    }
    return BuyV2CartAvoidanceRegion(
      key: ValueKey('buy-page-controls-protection-$scopeKey'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelWidth = buyV2ValueTextSize(
              context,
              range,
              rangeStyle,
              maxWidth: double.infinity,
              maxLines: 1,
            ).width;
            final inlineWidth =
                constraints.maxWidth - (area == null ? 144 : 192);
            if (labelWidth > inlineWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: summary,
                  ),
                  Row(
                    children: [previous, next, const Spacer(), refresh, ?area],
                  ),
                ],
              );
            }
            return Row(
              children: [
                previous,
                Expanded(child: summary),
                next,
                refresh,
                ?area,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CataloguePageNotice extends StatelessWidget {
  const _CataloguePageNotice({
    required this.title,
    required this.detail,
    this.action,
    this.onAction,
  });
  final String title;
  final String detail;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => BuyV2CartAvoidanceRegion(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.buyTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 4),
          Text(detail, style: context.buyMeta),
          if (onAction != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    ),
  );
}

Future<void> showBuyV2CatalogueArea(
  BuildContext context,
  BuyV2Session session,
) async {
  var search = '';
  var national = session.catalogueAreaScope == BuyV2CatalogueAreaScope.national;
  var request = 0;
  var loading = false;
  var locating = false;
  var results = <BuyV2ShoppingArea>[];
  String? failure;
  Timer? debounce;
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> lookup({bool currentLocation = false}) async {
            debounce?.cancel();
            final generation = ++request;
            setState(() {
              loading = true;
              locating = currentLocation;
              failure = null;
              results = [];
            });
            try {
              final found = currentLocation
                  ? await session.locateShoppingArea()
                  : await session.searchShoppingAreas(search);
              if (!context.mounted || generation != request) return;
              setState(() {
                loading = false;
                results = found;
              });
            } on Object catch (error) {
              if (!context.mounted || generation != request) return;
              setState(() {
                loading = false;
                failure = switch (error) {
                  BuyV2ShoppingAreaFailure.permissionDenied =>
                    'Location access is off. Search by locality or PIN code.',
                  BuyV2ShoppingAreaFailure.offline =>
                    'Areas could not load. Check your connection and try again.',
                  _ =>
                    'Area search is unavailable right now. Try again shortly.',
                };
              });
            }
          }

          final areas = session.catalogueAreaChoices.entries
              .where(
                (entry) =>
                    entry.value.toLowerCase().contains(search.toLowerCase()),
              )
              .toList(growable: false);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: FractionallySizedBox(
              heightFactor: .9,
              child: BuyV2VerticalScrollIndicator(
                child: ListView(
                  key: const ValueKey('buy-catalogue-area-list'),
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    16 +
                        BuyV2AddressSheetMotion.resolveBottomSafeInset(context),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Shopping area', style: context.buyTitle),
                        ),
                        IconButton(
                          tooltip: 'Close shopping area',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    TextField(
                      key: const ValueKey('buy-catalogue-area-search'),
                      maxLength: 80,
                      decoration: const InputDecoration(
                        hintText: 'Locality, city or PIN code',
                        counterText: '',
                      ),
                      onChanged: (value) {
                        debounce?.cancel();
                        request++;
                        setState(() {
                          search = value.trim();
                          results = [];
                          failure = null;
                          loading = false;
                          locating = false;
                        });
                        if (search.length >= 2) {
                          debounce = Timer(
                            const Duration(milliseconds: 350),
                            () {
                              if (context.mounted) unawaited(lookup());
                            },
                          );
                        }
                      },
                      onSubmitted: (_) {
                        if (search.length >= 2) unawaited(lookup());
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        key: const ValueKey('buy-catalogue-current-area'),
                        onPressed: loading
                            ? null
                            : () => lookup(currentLocation: true),
                        icon: const Icon(Icons.my_location_rounded),
                        label: const Text('Use current location'),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('In this area'),
                          selected: !national,
                          onSelected: (_) => setState(() => national = false),
                        ),
                        ChoiceChip(
                          label: const Text('National delivery'),
                          selected: national,
                          onSelected: (_) => setState(() => national = true),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Delivery availability is checked for your address.',
                      ),
                    ),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (failure != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              failure!,
                              key: const ValueKey('buy-area-lookup-failure'),
                            ),
                            TextButton(
                              key: const ValueKey('buy-area-lookup-retry'),
                              onPressed: () =>
                                  lookup(currentLocation: locating),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    if (results.isNotEmpty)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: BuyV2Colors.line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            for (final area in results)
                              ListTile(
                                key: ValueKey(
                                  'buy-google-area-${area.googlePlaceId}',
                                ),
                                title: Text(area.label),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (area.postalCode case final pin?)
                                      Text(pin),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        top: 5,
                                        bottom: 5,
                                      ),
                                      child: Text(
                                        'Google Maps',
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                          color: Color(0xff5e5e5e),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  if (session.chooseShoppingArea(
                                    area,
                                    national
                                        ? BuyV2CatalogueAreaScope.national
                                        : BuyV2CatalogueAreaScope.regional,
                                  )) {
                                    Navigator.of(context).pop();
                                  } else {
                                    setState(
                                      () => failure =
                                          'This area could not be selected. Search again.',
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ListTile(
                      key: const ValueKey('buy-catalogue-any-area'),
                      title: const Text('Any area'),
                      subtitle: const Text('Find stores in other areas.'),
                      onTap: () {
                        session.chooseCatalogueArea(
                          null,
                          BuyV2CatalogueAreaScope.allAreas,
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                    for (final area in areas)
                      ListTile(
                        key: ValueKey('buy-catalogue-area-${area.key}'),
                        title: Text(area.value),
                        onTap: () {
                          session.chooseCatalogueArea(
                            area.key,
                            national
                                ? BuyV2CatalogueAreaScope.national
                                : BuyV2CatalogueAreaScope.regional,
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    if (areas.isEmpty &&
                        results.isEmpty &&
                        !loading &&
                        failure == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No matching areas. You can still browse stores in any area.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  } finally {
    request++;
    debounce?.cancel();
  }
}

typedef BuyV2ProductVisit =
    Future<void> Function(BuyV2Product product, String returnLabel);

class BuyV2CatalogueView extends StatelessWidget {
  const BuyV2CatalogueView({
    super.key,
    required this.session,
    this.onOpenStore,
    this.onVisitProduct,
  });

  final BuyV2Session session;
  final ValueChanged<BuyV2Product>? onOpenStore;
  final BuyV2ProductVisit? onVisitProduct;

  @override
  Widget build(BuildContext context) {
    if (session.customerStateRecoveryPending) {
      return BuyV2CatalogueAvailabilityView(
        session: session,
        loading: session.customerStateRestoring,
        title: session.customerStateRestoring
            ? 'Restoring your Cart'
            : 'Your Cart is still saved',
      );
    }
    final savedOnly = session.showingSavedProducts;
    return Column(
      children: [
        if (session.canReturnToAccount)
          _CatalogueAccountReturn(session: session),
        _CatalogueToolbar(
          session: session,
          onVisitProduct: onVisitProduct,
          savedOnly: savedOnly,
          onSaved: () => session.showSavedProducts(!savedOnly),
        ),
        Expanded(
          child: _CatalogueMotionOwner(
            key: ValueKey(
              'buy-catalogue-motion-${session.destination.name}-'
              '${session.selectedCategoryId}-${session.saleTypeSignature}',
            ),
            destination: session.destination,
            child:
                session.pagedCatalogueEnabled &&
                    !savedOnly &&
                    !session.showingMonthlyBasketProducts
                ? BuyV2PagedProductCatalogue(
                    session: session,
                    query: session.catalogueQuery(),
                    scopeKey: 'catalogue-${session.destination.name}',
                    controlsAfterProducts:
                        session.destination == BuyV2Destination.shop,
                    header: session.query.trim().isEmpty || onOpenStore == null
                        ? null
                        : _CatalogueStoreMatches(
                            session: session,
                            query: session.catalogueQuery(),
                            onOpenStore: onOpenStore!,
                          ),
                    usePrimaryScrollController:
                        MediaQuery.sizeOf(context).width >
                            MediaQuery.sizeOf(context).height &&
                        MediaQuery.sizeOf(context).height <= 480,
                  )
                : BuyV2VerticalScrollIndicator(
                    child: _ProductGrid(
                      session: session,
                      savedOnly: savedOnly,
                      onShowAll: () => session.showSavedProducts(false),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CatalogueSaleTypeSelector extends StatelessWidget {
  const _CatalogueSaleTypeSelector({required this.session});

  final BuyV2Session session;

  static double minimumHorizontalWidth(
    BuildContext context,
    BuyV2Session session,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: session.destination == BuyV2Destination.shop
            ? 'Scheduled'
            : 'Wholesale',
        style: DefaultTextStyle.of(
          context,
        ).style.merge(_CatalogueSaleSegment.labelStyle(true)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
    )..layout();
    final width = 12 + 2 * painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final shop = session.destination == BuyV2Destination.shop;
    final options = shop
        ? const [
            (id: 'quick', title: 'Quick', icon: BuyV2DeliveryArtwork.quick),
            (
              id: 'courier',
              title: 'Scheduled',
              icon: BuyV2DeliveryArtwork.courier,
            ),
          ]
        : const [
            (
              id: 'wholesale',
              title: 'Wholesale',
              icon: BuyV2DeliveryArtwork.wholesale,
            ),
            (id: 'bulk', title: 'Bulk', icon: BuyV2DeliveryArtwork.bulk),
          ];
    final selectedIndex = shop
        ? session.shopSaleType == BuyV2ShopSaleType.quickDelivery
              ? 0
              : 1
        : session.wholesaleSaleType == BuyV2WholesaleSaleType.wholesale
        ? 0
        : 1;

    void select(int index) {
      if (index == selectedIndex) return;
      HapticFeedback.selectionClick();
      if (shop) {
        session.chooseShopSaleType(
          index == 0
              ? BuyV2ShopSaleType.quickDelivery
              : BuyV2ShopSaleType.courier,
        );
      } else {
        session.chooseWholesaleSaleType(
          index == 0
              ? BuyV2WholesaleSaleType.wholesale
              : BuyV2WholesaleSaleType.bulk,
        );
      }
    }

    return Semantics(
      key: ValueKey('buy-${shop ? 'shop' : 'wholesale'}-sale-type-selector'),
      container: true,
      explicitChildNodes: true,
      label: shop
          ? 'Choose Quick or scheduled Shop products'
          : 'Choose Wholesale or Bulk products',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minimumWidth = minimumHorizontalWidth(context, session);
          final vertical = constraints.maxWidth < minimumWidth;
          final showIcons =
              constraints.maxWidth >= minimumWidth + 50 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.25;
          final segmentWidth = constraints.maxWidth / (vertical ? 1 : 2);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() < 80) return;
              select(velocity < 0 ? 1 : 0);
            },
            child: SizedBox(
              key: ValueKey(
                'buy-${shop ? 'shop' : 'wholesale'}-sale-type-swipe',
              ),
              height: vertical ? 96 : 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    key: ValueKey(
                      'buy-${shop ? 'shop' : 'wholesale'}-sale-type-track',
                    ),
                    left: 0,
                    right: 0,
                    top: 7,
                    bottom: 7,
                    child: DecoratedBox(
                      key: ValueKey(
                        'buy-${shop ? 'shop' : 'wholesale'}-sale-type-'
                        'track-surface',
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3FF),
                        border: Border.all(color: const Color(0xFFCFD3F8)),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    key: ValueKey(
                      'buy-${shop ? 'shop' : 'wholesale'}-sale-type-thumb',
                    ),
                    duration: BuyV2Motion.resolved(
                      context,
                      BuyV2Motion.contentChange,
                    ),
                    curve: Curves.easeOutQuart,
                    left: vertical || selectedIndex == 0 ? 0 : segmentWidth,
                    top: vertical ? selectedIndex * 48.0 + 7 : 7,
                    bottom: vertical ? (1 - selectedIndex) * 48.0 + 7 : 7,
                    width: segmentWidth,
                    child: DecoratedBox(
                      key: ValueKey(
                        'buy-${shop ? 'shop' : 'wholesale'}-sale-type-'
                        'thumb-surface',
                      ),
                      decoration: const BoxDecoration(color: Color(0xFF1010A8)),
                    ),
                  ),
                  Flex(
                    direction: vertical ? Axis.vertical : Axis.horizontal,
                    children: [
                      for (var index = 0; index < options.length; index++)
                        Expanded(
                          child: _CatalogueSaleSegment(
                            key: ValueKey(
                              'buy-${shop ? 'shop' : 'wholesale'}-sale-type-'
                              '${options[index].id}',
                            ),
                            title: options[index].title,
                            icon: options[index].icon,
                            selected: selectedIndex == index,
                            showIcon: showIcons,
                            labelStyleKey: ValueKey(
                              'buy-${shop ? 'shop' : 'wholesale'}-sale-type-'
                              '${options[index].id}-label-style',
                            ),
                            onTap: () => select(index),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CatalogueSaleSegment extends StatelessWidget {
  const _CatalogueSaleSegment({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.showIcon,
    required this.labelStyleKey,
    required this.onTap,
  });

  final String title;
  final BuyV2DeliveryArtwork icon;
  final bool selected;
  final bool showIcon;
  final Key labelStyleKey;
  final VoidCallback onTap;

  static TextStyle labelStyle(bool selected) => TextStyle(
    color: selected ? Colors.white : BuyV2Colors.navy,
    fontSize: 11.25,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: selected ? .15 : .05,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: AnimatedSwitcher(
              key: ValueKey('buy-sale-type-segment-transition-$title'),
              duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
              reverseDuration: BuyV2Motion.resolved(
                context,
                BuyV2Motion.selection,
              ),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final eased = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: eased,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .12),
                      end: Offset.zero,
                    ).animate(eased),
                    child: child,
                  ),
                );
              },
              child: Row(
                key: ValueKey('$title-$selected'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showIcon) ...[
                    AnimatedScale(
                      duration: BuyV2Motion.resolved(
                        context,
                        BuyV2Motion.selection,
                      ),
                      curve: Curves.easeOutBack,
                      scale: selected ? 1.08 : .94,
                      child: AnimatedContainer(
                        key: ValueKey('buy-sale-type-icon-surface-$title'),
                        duration: BuyV2Motion.resolved(
                          context,
                          BuyV2Motion.selection,
                        ),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1010A8)
                                : const Color(0xFFCFD3F8),
                          ),
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x30000080),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ]
                              : const [],
                        ),
                        child: BuyV2DeliveryModeIcon(
                          artwork: icon,
                          size: 18,
                          color: const Color(0xFF1010A8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      key: labelStyleKey,
                      duration: BuyV2Motion.resolved(
                        context,
                        BuyV2Motion.selection,
                      ),
                      curve: Curves.easeOutCubic,
                      style: DefaultTextStyle.of(
                        context,
                      ).style.merge(labelStyle(selected)),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    final monthly = intent == BuyV2ShoppingIntent.monthlyBasket;
    final basketIds = monthly
        ? session.monthlyBasketPlan.map((line) => line.product.id).toSet()
        : const <String>{};
    final basketCartProducts = session.cartLines
        .where((line) => basketIds.contains(line.product.id))
        .length;
    if (monthly &&
        (session.destination != BuyV2Destination.shop ||
            (session.view != BuyV2View.catalogue &&
                session.view != BuyV2View.cart &&
                session.view != BuyV2View.checkout) ||
            (session.view == BuyV2View.checkout &&
                !session.checkoutDestinations.contains(
                  BuyV2Destination.shop,
                )) ||
            (session.view != BuyV2View.catalogue && basketCartProducts == 0))) {
      return const SizedBox.shrink();
    }
    final basketGroup = session.shopSaleType == BuyV2ShopSaleType.quickDelivery
        ? 'Quick'
        : 'Scheduled';
    final (title, detail, icon) = switch (intent) {
      BuyV2ShoppingIntent.monthlyBasket => (
        'Monthly basket',
        session.view != BuyV2View.catalogue
            ? '$basketCartProducts of 12 basket products in Shop ${session.view == BuyV2View.checkout ? 'order' : 'Cart'}'
            : '${session.catalogueSaleTypeProducts.length} of 12 basket products · $basketGroup',
        Icons.shopping_basket_outlined,
      ),
      BuyV2ShoppingIntent.businessBuying => (
        'Buying for business',
        'Wholesale packs for your business account',
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
                      maxLines: monthly ? null : 2,
                      overflow: monthly
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
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
      curve: Curves.easeOutQuart,
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

class _CatalogueStoreMatches extends StatefulWidget {
  const _CatalogueStoreMatches({
    required this.session,
    required this.query,
    required this.onOpenStore,
  });
  final BuyV2Session session;
  final BuyV2CatalogueQuery query;
  final ValueChanged<BuyV2Product> onOpenStore;

  @override
  State<_CatalogueStoreMatches> createState() => _CatalogueStoreMatchesState();
}

class _CatalogueStoreMatchesState extends State<_CatalogueStoreMatches>
    with WidgetsBindingObserver {
  late BuyV2CataloguePager<BuyV2StoreListing> _pager;
  late ScrollController _row;
  BuyV2CataloguePage<BuyV2StoreListing>? _shown;
  Timer? _expiry;
  int _sequence = 0;
  bool _restoring = false;
  String get _scope => 'store-search-${widget.query.destination.name}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attach();
  }

  void _attach() {
    _pager = widget.session.acquireCatalogueStores(_scope);
    _shown = _pager.page;
    _row = ScrollController(
      initialScrollOffset: _pager.laneOffset(0),
      keepScrollOffset: false,
    )..addListener(_rememberRow);
    _pager.addListener(_changed);
    _schedule();
    _scheduleExpiry();
  }

  void _rememberRow() {
    if (!_restoring &&
        _row.hasClients &&
        _pager.query == widget.query &&
        identical(_shown, _pager.page)) {
      _pager.rememberLaneOffset(0, _row.offset.clamp(0.0, double.infinity));
    }
  }

  void _schedule() {
    final sequence = ++_sequence;
    Future<void>.microtask(() async {
      if (!mounted || sequence != _sequence) return;
      if (_pager.query != widget.query ||
          (_pager.page == null && !_pager.loading && _pager.message == null)) {
        await _pager.open(widget.query);
      }
    });
  }

  void _scheduleExpiry() {
    _expiry?.cancel();
    final now = widget.session.catalogueNow();
    Duration? earliest;
    for (final original in _pager.page?.items ?? const <BuyV2StoreListing>[]) {
      final store = widget.session.catalogueStore(original.id) ?? original;
      final capability = store.collection;
      if (capability?.isSupportedFor(store.id, now: now) != true) continue;
      final remaining = capability!.validUntil.difference(now);
      if (earliest == null || remaining < earliest) earliest = remaining;
    }
    if (earliest != null) {
      _expiry = Timer(earliest, () {
        if (!mounted) return;
        setState(() {});
        _scheduleExpiry();
      });
    }
  }

  void _changed() {
    if (!mounted) return;
    if (!identical(_shown, _pager.page)) {
      _shown = _pager.page;
      _restoring = true;
      final page = _shown;
      final offset = _pager.laneOffset(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(page, _pager.page)) return;
        if (_row.hasClients) {
          _row.jumpTo(offset.clamp(0.0, _row.position.maxScrollExtent));
        }
        _restoring = false;
      });
    }
    _scheduleExpiry();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant _CatalogueStoreMatches oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.query.destination != widget.query.destination) {
      _detach(
        oldWidget.session,
        'store-search-${oldWidget.query.destination.name}',
      );
      _attach();
    } else if (oldWidget.query != widget.query) {
      _schedule();
    }
    _scheduleExpiry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() {});
    _scheduleExpiry();
  }

  void _detach(BuyV2Session session, String scope) {
    _sequence++;
    _expiry?.cancel();
    _rememberRow();
    _pager.removeListener(_changed);
    _row.dispose();
    session.releaseCatalogueStores(scope);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detach(widget.session, _scope);
    super.dispose();
  }

  String _location(BuyV2StoreListing store) {
    final distance = store.distanceMeters;
    final location = store.address.contains(store.area)
        ? store.address
        : '${store.area} · ${store.address}';
    if (distance == null) return location;
    return '$location · ${distance < 1000 ? '${distance.round()} m' : '${(distance / 1000).toStringAsFixed(1)} km'}';
  }

  @override
  Widget build(BuildContext context) {
    final page = _pager.query == widget.query ? _pager.page : null;
    final loading = _pager.query != widget.query || _pager.loading;
    final message = _pager.query == widget.query ? _pager.message : null;
    final stores = [
      for (final store in page?.items ?? const <BuyV2StoreListing>[])
        widget.session.catalogueStore(store.id) ?? store,
    ];
    if (!loading && message == null && stores.isEmpty) {
      return const SizedBox.shrink();
    }
    final scaler = MediaQuery.textScalerOf(context);
    final width = MediaQuery.sizeOf(context).width < 400 ? 230.0 : 280.0;
    final titleStyle = context.buyBody.copyWith(fontWeight: FontWeight.w900);
    final detailStyle = context.buyMeta;
    final actionStyle = detailStyle.copyWith(fontWeight: FontWeight.w800);
    final now = widget.session.catalogueNow();
    double heightFor(BuyV2StoreListing store) {
      double measure(String text, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: scaler,
        )..layout(maxWidth: width - 24);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      return 34 +
          measure(store.name, titleStyle) +
          measure(_location(store), detailStyle) +
          measure(
            store.previewProduct == null
                ? 'Products unavailable'
                : store.collection?.isSupportedFor(store.id, now: now) == true
                ? 'Collect at store'
                : 'View store',
            actionStyle,
          );
    }

    final height = stores.fold<double>(44, (value, store) {
      final candidate = heightFor(store);
      return candidate > value ? candidate : value;
    });
    return Column(
      key: ValueKey(
        'buy-store-search-results-${widget.query.destination.name}',
      ),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CataloguePageControls(
          scopeKey: _scope,
          noun: 'stores',
          start: page?.startIndex,
          count: stores.length,
          total: page?.totalCount,
          loading: loading,
          onPrevious: !loading && page?.previousCursor != null
              ? _pager.previous
              : null,
          onNext: !loading && page?.nextCursor != null ? _pager.next : null,
          onRefresh: loading ? null : _pager.refresh,
        ),
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (message != null)
          _CataloguePageNotice(
            title: 'Stores could not refresh',
            detail: message,
            action: 'Try stores again',
            onAction: loading ? null : _pager.retry,
          ),
        if (stores.isNotEmpty)
          SizedBox(
            height: height,
            child: ListView.separated(
              key: ValueKey(
                'buy-store-search-row-${widget.query.destination.name}',
              ),
              controller: _row,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: stores.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final store = stores[index];
                final product = store.previewProduct;
                final collect =
                    store.collection?.isSupportedFor(store.id, now: now) ==
                    true;
                return SizedBox(
                  width: width,
                  child: BuyV2CartAvoidanceRegion(
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: BuyV2Colors.line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('buy-store-search-open-${store.id}'),
                        onTap: product == null
                            ? null
                            : () => widget.onOpenStore(product),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(store.name, style: titleStyle),
                              const SizedBox(height: 3),
                              Text(_location(store), style: detailStyle),
                              const SizedBox(height: 5),
                              Text(
                                product == null
                                    ? 'Products unavailable'
                                    : collect
                                    ? 'Collect at store'
                                    : 'View store',
                                style: actionStyle.copyWith(
                                  color: collect
                                      ? BuyV2Colors.green
                                      : BuyV2Colors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class BuyV2SearchResultsView extends StatelessWidget {
  const BuyV2SearchResultsView({
    super.key,
    required this.session,
    this.onOpenStore,
  });

  final BuyV2Session session;
  final ValueChanged<BuyV2Product>? onOpenStore;

  @override
  Widget build(BuildContext context) {
    final query = session.query.trim();
    if (session.pagedCatalogueEnabled && query.isNotEmpty) {
      return BuyV2PagedProductCatalogue(
        session: session,
        query: session.catalogueQuery(),
        scopeKey: 'search-${session.destination.name}',
        header: onOpenStore == null
            ? null
            : _CatalogueStoreMatches(
                session: session,
                query: session.catalogueQuery(),
                onOpenStore: onOpenStore!,
              ),
        usePrimaryScrollController:
            MediaQuery.sizeOf(context).width >
                MediaQuery.sizeOf(context).height &&
            MediaQuery.sizeOf(context).height <= 480,
      );
    }
    final products = session.visibleProducts;
    return BuyV2FiniteIncomingTransition(
      key: const ValueKey('buy-search-results-surface'),
      stateKey:
          'buy-query-results-${session.destination.name}-'
          '${session.selectedCategoryId}-'
          '${session.selectedFilter ?? 'none'}-'
          '${session.discoveryRefinementSignature}-'
          '${query.toLowerCase()}',
      child: BuyV2VerticalScrollIndicator(
        key: ValueKey('buy-search-scroll-${session.destination.name}-$query'),
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
        children:
            [
                  if (recentSearches.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
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
                            onPressed: () => session.clearRecentSearches(
                              session.destination,
                            ),
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
                    const Divider(
                      height: 1,
                      indent: 42,
                      color: BuyV2Colors.line,
                    ),
                  ],
                  if (recentSearches.isNotEmpty && suggestions.isNotEmpty)
                    const SizedBox(height: 4),
                  for (final (index, suggestion) in suggestions.indexed) ...[
                    Semantics(
                      button: true,
                      label:
                          'Search ${session.destination.label} for $suggestion',
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
                      const Divider(
                        height: 1,
                        indent: 42,
                        color: BuyV2Colors.line,
                      ),
                  ],
                ]
                .map((child) => BuyV2CartAvoidanceRegion(child: child))
                .toList(growable: false),
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
              child: BuyV2CartAvoidanceRegion(
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
            ),
          );
        },
      );
    }
    return _QuantityAwareGridLayout(
      session: session,
      products: products,
      builder: (context, constraints, quantityWidth) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        final layout = _resolveCompactProductGridLayout(
          constraints: constraints,
          accessibleText: accessibleText,
          textScale: textScale,
          cartQuantityWidth: quantityWidth,
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
                laneCount: products.length <= layout.columns ? 1 : null,
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
    this.onVisitProduct,
  });

  final BuyV2Session session;
  final bool savedOnly;
  final VoidCallback onSaved;
  final BuyV2ProductVisit? onVisitProduct;

  @override
  Widget build(BuildContext context) {
    final order = session.orders
        .where(
          (order) =>
              order.destination == session.destination ||
              session.destination == BuyV2Destination.shop,
        )
        .firstOrNull;
    return BuyV2CartAvoidanceRegion(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final separateModeRow =
              (session.destination == BuyV2Destination.shop ||
                  session.destination == BuyV2Destination.wholesale) &&
              constraints.maxWidth - 171 <
                  _CatalogueSaleTypeSelector.minimumHorizontalWidth(
                    context,
                    session,
                  );
          final category = _CatalogueCategoryPickerButton(session: session);
          final feature = _CatalogueOwnedFeature(session: session);
          final saved = _CompactCatalogueAction(
            key: const ValueKey('buy-saved-products-button'),
            icon: savedOnly
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: savedOnly ? 'Show all products' : 'Show Saved products',
            badge: '${session.savedCountFor(session.destination)}',
            active: savedOnly,
            onTap: onSaved,
          );
          final tools = _CatalogueToolsMenu(
            session: session,
            order: order,
            onVisitProduct: onVisitProduct,
          );
          return Container(
            key: const ValueKey('buy-catalogue-toolbar'),
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFF9F2),
                  Color(0xFFF8F8FF),
                  Color(0xFFF5F8FF),
                ],
              ),
              border: Border(bottom: BorderSide(color: BuyV2Colors.line)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x10000080),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: separateModeRow
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      feature,
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [category, saved, tools],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      category,
                      const SizedBox(width: 5),
                      Expanded(child: feature),
                      const SizedBox(width: 5),
                      saved,
                      const SizedBox(width: 5),
                      tools,
                    ],
                  ),
          );
        },
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
    return _CatalogueChromeAction(
      key: const ValueKey('buy-category-picker'),
      label:
          'Choose ${session.destination.label} category. '
          'Current category ${selected.label}',
      tooltip: '${session.destination.label} categories · ${selected.label}',
      icon: Icons.grid_view_rounded,
      emphasized: true,
      onTap: () => showBuyV2CategoryPicker(context, session),
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
    if (session.destination == BuyV2Destination.shop ||
        session.destination == BuyV2Destination.wholesale) {
      return _CatalogueSaleTypeSelector(session: session);
    }
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
          heightFactor: MediaQuery.sizeOf(context).height < 480
              ? 1
              : BuyV2CategorySheetPolicy.heightFactorFor(context),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.sizeOf(context).height < 480
                  ? 8
                  : MoolMetrics.compactTapTarget,
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
                                      maxLines:
                                          MediaQuery.textScalerOf(
                                                context,
                                              ).scale(1) >
                                              1.25
                                          ? 2
                                          : 1,
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
                              : BuyV2VerticalScrollIndicator(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final labelSize = MediaQuery.textScalerOf(
                                        context,
                                      ).scale(10);
                                      final columns = labelSize > 12.5
                                          ? (constraints.maxWidth / 160)
                                                .floor()
                                                .clamp(2, 3)
                                          : constraints.maxWidth < 350
                                          ? 2
                                          : 3;
                                      return GridView.builder(
                                        key: const ValueKey(
                                          'buy-category-grid',
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          10,
                                        ),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: columns,
                                              mainAxisExtent:
                                                  84 +
                                                  (labelSize - 10).clamp(
                                                        0,
                                                        double.infinity,
                                                      ) *
                                                      2.1,
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
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration: BoxDecoration(
                                                                color: selected
                                                                    ? Colors
                                                                          .white
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
                                                              width: double
                                                                  .infinity,
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
                                                            color: BuyV2Colors
                                                                .green,
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
    return _CatalogueChromeAction(
      label: badge == null ? label : '$label, $badge saved',
      tooltip: label,
      icon: icon,
      badge: badge,
      active: active,
      iconMotionKey: const ValueKey('buy-saved-filter-icon-motion'),
      onTap: onTap,
    );
  }
}

class _CatalogueChromeAction extends StatefulWidget {
  const _CatalogueChromeAction({
    super.key,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.badge,
    this.active = false,
    this.emphasized = false,
    this.iconMotionKey,
  });

  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;
  final bool active;
  final bool emphasized;
  final Key? iconMotionKey;

  @override
  State<_CatalogueChromeAction> createState() => _CatalogueChromeActionState();
}

class _CatalogueChromeActionState extends State<_CatalogueChromeAction> {
  bool _pressed = false;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || widget.emphasized;
    return Semantics(
      label: widget.label,
      button: true,
      excludeSemantics: true,
      onTap: _activate,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
          curve: Curves.easeOutCubic,
          scale: _pressed ? .93 : 1,
          child: AnimatedSlide(
            duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
            curve: Curves.easeOutCubic,
            offset: _pressed ? const Offset(0, .035) : Offset.zero,
            child: AnimatedContainer(
              duration: BuyV2Motion.resolved(context, BuyV2Motion.selection),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: highlighted
                      ? const [Color(0xFFFFE8CE), Colors.white]
                      : const [Colors.white, Color(0xFFF4F3FF)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: highlighted ? BuyV2Colors.orange : BuyV2Colors.line,
                  width: highlighted ? 1.15 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: highlighted
                        ? const Color(0x30FF9933)
                        : const Color(0x1A000080),
                    blurRadius: highlighted ? 12 : 9,
                    offset: const Offset(0, 4),
                  ),
                  const BoxShadow(
                    color: Color(0xB8FFFFFF),
                    blurRadius: 2,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: _activate,
                  onHighlightChanged: (value) {
                    if (_pressed == value) return;
                    setState(() => _pressed = value);
                  },
                  borderRadius: BorderRadius.circular(16),
                  splashColor: BuyV2Colors.orange.withValues(alpha: .18),
                  highlightColor: BuyV2Colors.softOrange.withValues(alpha: .3),
                  child: Center(
                    child: Badge(
                      isLabelVisible: widget.badge != null,
                      label: widget.badge == null
                          ? null
                          : Text(
                              widget.badge!,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                      backgroundColor: BuyV2Colors.orange,
                      textColor: BuyV2Colors.navy,
                      child: BuyV2FiniteVisualTransition(
                        key: widget.iconMotionKey,
                        stateKey: widget.icon,
                        ownerSize: const Size.square(22),
                        child: Icon(
                          widget.icon,
                          size: 22,
                          color: highlighted
                              ? BuyV2Colors.royal
                              : BuyV2Colors.navy,
                        ),
                      ),
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

class _CatalogueToolsMenu extends StatelessWidget {
  const _CatalogueToolsMenu({
    required this.session,
    required this.order,
    this.onVisitProduct,
  });
  final BuyV2ProductVisit? onVisitProduct;

  final BuyV2Session session;
  final BuyV2Order? order;

  @override
  Widget build(BuildContext context) {
    final filterOptions = _filterOptionsFor(session.destination);
    final refinementCount = session.activeDiscoveryRefinementCount;
    final namedFulfilmentFilter = session.selectedFulfilmentMode != null;
    final currentFilterLabel = session.destination == BuyV2Destination.shop
        ? (session.shopSaleType == BuyV2ShopSaleType.quickDelivery
              ? 'Quick delivery'
              : 'Scheduled delivery')
        : session.destination == BuyV2Destination.wholesale
        ? (session.wholesaleSaleType == BuyV2WholesaleSaleType.wholesale
              ? 'Wholesale'
              : 'Bulk')
        : namedFulfilmentFilter
        ? buyV2FulfilmentModeLabel(session.selectedFulfilmentMode!)
        : _filterLabel(filterOptions, session.selectedFilter);
    final additionalFilterCount =
        refinementCount -
        (namedFulfilmentFilter ? 1 : 0) +
        (session.selectedFilter == null ? 0 : 1);
    void openSheet() {
      HapticFeedback.selectionClick();
      final openFilters = session.destination == BuyV2Destination.medicine
          ? showBuyV2FilterSheet
          : showBuyV2DiscoveryRefinementSheet;
      openFilters(
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
              detail: () {
                final count = session
                    .recentlyViewedProductsFor(session.destination)
                    .length;
                return count == 0
                    ? 'Products you open will appear here'
                    : '$count ${count == 1 ? 'product' : 'products'} ready to revisit';
              }(),
              onTap: () => showBuyV2RecentlyViewed(
                context,
                session,
                onVisitProduct: onVisitProduct,
              ),
            ),
          if (session.destination == BuyV2Destination.shop ||
              session.destination == BuyV2Destination.wholesale)
            BuyV2FilterSheetAction(
              keyName: 'buy-shopping-settings-button',
              icon: Icons.tune_rounded,
              title: 'Shopping settings',
              detail: 'Delivery, payments, alerts and saved activity',
              onTap: () => showBuyV2ShoppingSettings(
                context,
                session,
                onVisitProduct: onVisitProduct,
              ),
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

    return _CatalogueChromeAction(
      key: const ValueKey('buy-filter-button'),
      label:
          'Open ${session.destination.label} tools and filters. '
          'Current $currentFilterLabel. '
          '$additionalFilterCount additional '
          '${additionalFilterCount == 1 ? 'filter' : 'filters'} selected',
      tooltip: 'Sort and filter',
      icon: Icons.tune_rounded,
      badge: session.selectedFilter != null || refinementCount > 0
          ? '${refinementCount + (session.selectedFilter == null ? 0 : 1)}'
          : null,
      active: session.selectedFilter != null || refinementCount > 0,
      onTap: openSheet,
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
  BuyV2Session session, {
  BuyV2ProductVisit? onVisitProduct,
}) async {
  final selectedProductId = await showModalBottomSheet<String>(
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
        unawaited(
          showBuyV2SavedProducts(
            sheetContext,
            session,
            onVisitProduct: onVisitProduct,
            onOpenProduct: (productId) {
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop(productId);
              }
            },
          ),
        );
      },
      onOpenRecentlyViewed: () {
        unawaited(
          showBuyV2RecentlyViewed(
            sheetContext,
            session,
            onVisitProduct: onVisitProduct,
            onOpenProduct: (productId) {
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop(productId);
              }
            },
          ),
        );
      },
    ),
  );
  if (selectedProductId != null) session.openProduct(selectedProductId);
}

class _BuyV2ShoppingSettingsSheet extends StatefulWidget {
  const _BuyV2ShoppingSettingsSheet({
    required this.session,
    required this.onOpenSavedProducts,
    required this.onOpenRecentlyViewed,
  });

  final BuyV2Session session;
  final VoidCallback onOpenSavedProducts;
  final VoidCallback onOpenRecentlyViewed;

  @override
  State<_BuyV2ShoppingSettingsSheet> createState() =>
      _BuyV2ShoppingSettingsSheetState();
}

class _BuyV2ShoppingSettingsSheetState
    extends State<_BuyV2ShoppingSettingsSheet> {
  final _scrollController = ScrollController();
  BuyV2Session get session => widget.session;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final recentCount = session
            .recentlyViewedProductsFor(session.destination)
            .length;
        final savedCount =
            session.savedCountFor(BuyV2Destination.shop) +
            session.savedCountFor(BuyV2Destination.wholesale);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('buy-shopping-settings'),
            controller: _scrollController,
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
                  onTap: widget.onOpenSavedProducts,
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-recently-viewed'),
                  icon: Icons.history_rounded,
                  title: 'Recently viewed',
                  detail: recentCount == 0
                      ? '${session.destination.label} · No recently viewed products'
                      : '${session.destination.label} · $recentCount recently viewed',
                  onTap: recentCount == 0 ? null : widget.onOpenRecentlyViewed,
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-messages'),
                  icon: Icons.forum_outlined,
                  title: 'Seller messages',
                  detail: 'Open your Shop conversations',
                  onTap: () => _openBuyV2SettingsRoute(
                    context,
                    Uri(
                      path: '/app/chat/inbox',
                      queryParameters: {
                        'type': 'business',
                        'return': '/app/buy',
                      },
                    ).toString(),
                    returnScrollController: _scrollController,
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
                    returnScrollController: _scrollController,
                  ),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-security'),
                  icon: Icons.security_outlined,
                  title: 'Security and account controls',
                  detail: 'Review sign-in, sessions and account access',
                  onTap: () => _openBuyV2SettingsRoute(
                    context,
                    '/app/account/security',
                    returnScrollController: _scrollController,
                  ),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-help'),
                  icon: Icons.help_outline_rounded,
                  title: 'Help and support',
                  detail: 'Get help with shopping and orders',
                  onTap: () => _showBuyV2ShoppingHelp(
                    context,
                    widget.session,
                    returnScrollController: _scrollController,
                  ),
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
                  Text(detail, style: context.buyMeta),
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

String _shoppingAlertDetail(BuyV2ShoppingAlert alert, BuyV2Session session) {
  final order = session.orders
      .where((order) => order.id == alert.orderId)
      .firstOrNull;
  if (order == null ||
      order.status == BuyV2OrderStatus.delivered ||
      order.promise.isEmpty ||
      !alert.detail.endsWith(order.promise)) {
    return alert.detail;
  }
  return '${alert.detail.substring(0, alert.detail.length - order.promise.length)}'
      '${buyV2OrderPromiseSummary(order)}';
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

Future<void> _showBuyV2ShoppingHelp(
  BuildContext context,
  BuyV2Session session, {
  required ScrollController returnScrollController,
}) async {
  final offset = returnScrollController.hasClients
      ? returnScrollController.offset
      : null;
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
    builder: (_) => _BuyV2ShoppingHelpSheet(session: session),
  );
  if (!context.mounted) return;
  _restoreBuyV2SettingsOffset(context, returnScrollController, offset);
}

class _BuyV2ShoppingHelpSheet extends StatefulWidget {
  const _BuyV2ShoppingHelpSheet({required this.session});
  final BuyV2Session session;

  @override
  State<_BuyV2ShoppingHelpSheet> createState() =>
      _BuyV2ShoppingHelpSheetState();
}

class _BuyV2ShoppingHelpSheetState extends State<_BuyV2ShoppingHelpSheet> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  bool _visiting = false;
  String? _routeError;

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openOrder(BuyV2Order order) async {
    final router = GoRouter.maybeOf(context);
    if (router == null || _visiting) return;
    FocusScope.of(context).unfocus();
    final offset = _scroll.hasClients ? _scroll.offset : null;
    final visit = widget.session.beginShoppingHelpOrderVisit(order.id, () {
      if (mounted && router.canPop()) router.pop();
    });
    if (visit == null) {
      setState(
        () => _routeError = 'This order cannot be opened right now. Try again.',
      );
      return;
    }
    setState(() {
      _visiting = true;
      _routeError = null;
    });
    final session = widget.session;
    unawaited(
      ModalRoute.of(context)!.completed.then<void>((_) {
        session.finishShoppingHelpOrderVisit(visit, restore: false);
      }),
    );
    try {
      await router.push(
        Uri(
          path: '/app/buy',
          queryParameters: {
            'sub': 'orders',
            'view': 'tracking',
            'order': order.id,
          },
        ).toString(),
      );
    } finally {
      session.finishShoppingHelpOrderVisit(visit, restore: mounted);
      if (mounted) {
        setState(() => _visiting = false);
        _restoreBuyV2SettingsOffset(context, _scroll, offset);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final media = MediaQuery.of(context);
      final query = _search.text.trim().toLowerCase();
      final orders = widget.session.orders
          .where(
            (order) =>
                order.destination == BuyV2Destination.shop ||
                order.destination == BuyV2Destination.wholesale,
          )
          .where(
            (order) =>
                query.isEmpty ||
                [
                  order.id,
                  order.purchaseId ?? '',
                  order.title,
                  order.itemSummary,
                  order.partner,
                  for (final id in order.productIds)
                    widget.session.findProduct(id)?.title ?? '',
                  for (final line in order.lines) line.product.title,
                ].any((value) => value.toLowerCase().contains(query)),
          )
          .toList();
      final canOpenOrders = GoRouter.maybeOf(context) != null;
      return Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          key: const ValueKey('buy-shopping-help'),
          height:
              ((media.size.height -
                          media.viewInsets.bottom -
                          media.viewPadding.top) *
                      .9)
                  .clamp(0.0, media.size.height),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Shopping help',
                          style: context.buyTitle.copyWith(fontSize: 17),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('buy-shopping-help-close'),
                        tooltip: 'Close shopping help',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    key: const ValueKey('buy-shopping-help-list'),
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                    itemCount: orders.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Products, delivery, invoices and returns.',
                              style: context.buyMeta,
                            ),
                            ExpansionTile(
                              key: const ValueKey(
                                'buy-shopping-help-before-order',
                              ),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              title: Text(
                                'Before you order',
                                style: context.buyBody,
                              ),
                              children: [
                                Text(
                                  'Open a product to check its pack, price, minimum order and delivery details. Visit its store or supplier for seller information and available contact options.',
                                  style: context.buyMeta,
                                ),
                              ],
                            ),
                            ExpansionTile(
                              key: const ValueKey(
                                'buy-shopping-help-order-guidance',
                              ),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(
                                bottom: 10,
                              ),
                              title: Text(
                                'Delivery, returns and refunds',
                                style: context.buyBody,
                              ),
                              children: [
                                Text(
                                  'Choose an order below for tracking, invoices and available help with delivery, returns or refunds.',
                                  style: context.buyMeta,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Your Shop and Wholesale orders',
                              style: context.buyBody,
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              key: const ValueKey('buy-shopping-help-search'),
                              controller: _search,
                              scrollPadding: const EdgeInsets.all(16),
                              onChanged: (_) => setState(() {}),
                              onTapOutside: (_) =>
                                  FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                labelText: 'Find an order',
                                hintText: 'Order number, product or seller',
                                suffixIcon: _search.text.isEmpty
                                    ? null
                                    : IconButton(
                                        key: const ValueKey(
                                          'buy-shopping-help-clear',
                                        ),
                                        tooltip: 'Clear order search',
                                        onPressed: () =>
                                            setState(_search.clear),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (!canOpenOrders)
                              Text(
                                'Order details are unavailable here.',
                                style: context.buyMeta,
                              ),
                            if (_routeError != null)
                              Text(_routeError!, style: context.buyMeta),
                            if (orders.isEmpty)
                              Text(
                                query.isEmpty
                                    ? 'No orders to show yet.'
                                    : 'No matching orders. Try another order number, product or seller.',
                                key: const ValueKey('buy-shopping-help-empty'),
                                style: context.buyBody,
                              ),
                          ],
                        );
                      }
                      final order = orders[index - 1];
                      final status = switch (order.status) {
                        BuyV2OrderStatus.confirmed => 'Order confirmed',
                        BuyV2OrderStatus.preparing => 'Preparing your order',
                        BuyV2OrderStatus.dispatched => 'Dispatched',
                        BuyV2OrderStatus.arriving => 'Arriving',
                        BuyV2OrderStatus.delivered => 'Delivered',
                      };
                      return _ShoppingSettingsRow(
                        key: ValueKey('buy-shopping-help-order-${order.id}'),
                        icon: Icons.receipt_long_outlined,
                        title: '${order.id} · ${order.destination.label}',
                        detail:
                            '${order.itemSummary}\n${order.partner}\n$status',
                        onTap: !canOpenOrders || _visiting
                            ? null
                            : () => _openOrder(order),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _restoreBuyV2SettingsOffset(
  BuildContext context,
  ScrollController returnScrollController,
  double? offset,
) {
  if (!context.mounted || offset == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted || !returnScrollController.hasClients) return;
    final position = returnScrollController.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (position.pixels != target) returnScrollController.jumpTo(target);
  });
}

Future<void> _openBuyV2SettingsRoute(
  BuildContext context,
  String route, {
  required ScrollController returnScrollController,
}) async {
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  final offset = returnScrollController.hasClients
      ? returnScrollController.offset
      : null;
  await router.push(route);
  if (!context.mounted) return;
  // A keyboard on the pushed page can resize and clamp the covered sheet.
  // Restore its actual origin after the returned page has laid out again.
  _restoreBuyV2SettingsOffset(context, returnScrollController, offset);
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
        Future<void> openAlert(BuyV2ShoppingAlert alert) async {
          if (router == null || session.hasShoppingAlertReturnOrigin) return;
          final location = buyV2ShoppingAlertLocation(alert);
          final visit = session.beginShoppingAlertVisit(alert, () {
            if (sheetContext.mounted && router.canPop()) router.pop();
          });
          unawaited(
            ModalRoute.of(sheetContext)!.completed.then<void>((_) {
              session.finishShoppingAlertVisit(visit, restore: false);
            }),
          );
          try {
            await router.push(location);
          } finally {
            session.finishShoppingAlertVisit(
              visit,
              restore: sheetContext.mounted,
            );
          }
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
                          [
                                alert.title,
                                _shoppingAlertDetail(alert, session),
                                alert.updatedLabel,
                              ]
                              .map(
                                (value) => value.trim().replaceFirst(
                                  RegExp(r'[.!?]+$'),
                                  '',
                                ),
                              )
                              .join('. '),
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
                                      _shoppingAlertDetail(alert, session),
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
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => _HouseholdBasket(
        session: session,
        onClose: () => Navigator.of(sheetContext).pop(),
        onSeeProducts: () =>
            Navigator.of(sheetContext).pop(_HouseholdBasketAction.seeProducts),
        onAddToCart: () =>
            Navigator.of(sheetContext).pop(_HouseholdBasketAction.addToCart),
      ),
    ),
  );
  switch (action) {
    case _HouseholdBasketAction.seeProducts:
      session.chooseCategory('all');
      session.showNotice(
        'Choose Quick or Scheduled to view each basket group.',
      );
      break;
    case _HouseholdBasketAction.addToCart:
      session.addMonthlyBasket();
      break;
    case null:
      break;
  }
}

Future<void> showBuyV2SavedProducts(
  BuildContext context,
  BuyV2Session session, {
  ValueChanged<String>? onOpenProduct,
  BuyV2ProductVisit? onVisitProduct,
}) async {
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
      onOpenProduct: (productId) {
        if (onVisitProduct != null) {
          unawaited(
            onVisitProduct(session.product(productId), 'Saved products'),
          );
        } else {
          Navigator.of(sheetContext).pop(productId);
        }
      },
    ),
  );
  if (selectedProductId != null) {
    if (onOpenProduct != null) {
      onOpenProduct(selectedProductId);
    } else {
      session.openProduct(selectedProductId);
    }
  }
}

Future<void> showBuyV2RecentlyViewed(
  BuildContext context,
  BuyV2Session session, {
  ValueChanged<String>? onOpenProduct,
  BuyV2ProductVisit? onVisitProduct,
}) async {
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
      onOpenProduct: (productId) {
        if (onVisitProduct != null) {
          unawaited(
            onVisitProduct(session.product(productId), 'Recently viewed'),
          );
        } else {
          Navigator.of(sheetContext).pop(productId);
        }
      },
      onClear: () => _confirmClearBuyV2RecentlyViewed(sheetContext, session),
    ),
  );
  if (selectedProductId != null) {
    if (onOpenProduct != null) {
      onOpenProduct(selectedProductId);
    } else {
      session.openProduct(selectedProductId);
    }
  }
}

Future<void> showBuyV2PartnerCatalogue(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product current, {
  bool brandOnly = false,
  ValueChanged<BuyV2Product>? onAskStore,
  ValueChanged<BuyV2Product>? onStoreChanged,
  Future<bool> Function(BuyV2Product product)? onOpenProduct,
  VoidCallback? onOpenCart,
  ValueChanged<BuyV2Product>? onOpenStoreCart,
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
  final publicPartner =
      !brandOnly &&
      (current.destination == BuyV2Destination.shop ||
          current.destination == BuyV2Destination.wholesale);
  final pagedPartner =
      publicPartner && session.pagedCatalogueEnabled && current.storeId != null;
  final canViewAll = !brandOnly && (pagedPartner || products.length > 1);
  if (!supportedDestination || (products.isEmpty && !publicPartner)) return;
  if (pagedPartner) {
    session.retainCatalogueStoreBrowse(current);
    unawaited(
      session.refreshCatalogueStore(current.storeId!, current.destination),
    );
  }
  final previewProducts = products.take(6).toList(growable: false);
  final storeTrust = session.marketplaceTrustFor(current);
  final storeFulfilment = publicPartner
      ? _publicStoreFulfilmentLabels(
          session,
          products.isEmpty ? [current] : products,
        )
      : const <String>[];
  final otherStores = brandOnly
      ? const <BuyV2Product>[]
      : session.otherStorePreviewsFor(current);
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
      : current.destination == BuyV2Destination.wholesale
      ? 'Supplier products'
      : 'Store products';
  final detail = brandOnly
      ? 'Browse ${products.length} available ${current.brand} products'
      : switch (current.destination) {
          BuyV2Destination.wholesale =>
            '${products.length} ${products.length == 1 ? 'pack' : 'packs'} · '
                'Minimums, prices and delivery',
          BuyV2Destination.medicine =>
            '${products.length} products · Packs and prices · Not medical advice',
          _ =>
            '${products.length} '
                '${products.length == 1 ? 'product' : 'products'} · '
                'Delivery options',
        };
  final closeTooltip = brandOnly
      ? 'Close brand products'
      : switch (current.destination) {
          BuyV2Destination.wholesale => 'Close supplier products',
          BuyV2Destination.medicine => 'Close pharmacy products',
          _ => 'Close store',
        };
  final motion = BuyV2SupplierSheetMotion.resolve(context);
  Future<void> openStoreProduct(
    BuildContext sheetContext,
    BuyV2Product product,
  ) async {
    final handler = onOpenProduct;
    if (handler == null) {
      Navigator.of(sheetContext).pop(product.id);
      return;
    }
    final openCart = await handler(product);
    if (openCart && sheetContext.mounted) {
      Navigator.of(sheetContext).pop('cart:');
    }
  }

  Future<void> openFullStoreCatalogue(BuildContext sheetContext) async {
    final productId = await _showBuyV2FullStoreCatalogue(
      sheetContext,
      session,
      current,
      products,
      ownerPrefix,
      onOpenProduct: onOpenProduct,
      onOpenCart: onOpenStoreCart == null
          ? null
          : () => onOpenStoreCart(current),
    );
    if (productId == null || !sheetContext.mounted) return;
    if (productId == 'cart:') {
      Navigator.of(sheetContext).pop('cart:');
      return;
    }
    await openStoreProduct(sheetContext, session.product(productId));
  }

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
      showDragHandle: false,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(
        maxWidth: BuyV2SupplierSheetMotion.maxWidth,
      ),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      transitionAnimationController: transitionController,
      builder: (sheetContext) => AnimatedBuilder(
        animation: session,
        builder: (context, _) => FractionallySizedBox(
          key: ValueKey('$ownerPrefix-route-${current.id}'),
          heightFactor: 1,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: Semantics(
                    key: ValueKey('$ownerPrefix-sheet-${current.id}'),
                    container: true,
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: title,
                    child: BuyV2VerticalScrollIndicator(
                      child: ListView(
                        key: ValueKey('$ownerPrefix-sheet-list'),
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        children: [
                          Row(
                            key: ValueKey('$ownerPrefix-sheet-header'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: BuyV2Colors.softOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  brandOnly
                                      ? Icons.sell_outlined
                                      : Icons.storefront_outlined,
                                  color: BuyV2Colors.navy,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: canViewAll
                                        ? ValueKey(
                                            '$ownerPrefix-view-more-${current.id}',
                                          )
                                        : null,
                                    onTap: canViewAll
                                        ? () => unawaited(
                                            openFullStoreCatalogue(
                                              sheetContext,
                                            ),
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(9),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: BuyV2Metrics.minimumTap,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.clip,
                                            style: sheetContext.buyTitle
                                                .copyWith(
                                                  fontSize: 14,
                                                  height: 1.08,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          if (canViewAll)
                                            Row(
                                              key: ValueKey(
                                                '$ownerPrefix-view-more-visible-${current.id}',
                                              ),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.grid_view_rounded,
                                                  size: 13,
                                                  color: BuyV2Colors.navy,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    pagedPartner
                                                        ? 'Browse all products'
                                                        : '${products.length} ${current.destination == BuyV2Destination.wholesale ? 'packs' : 'products'} · View all',
                                                    overflow: TextOverflow.clip,
                                                    style: sheetContext.buyMeta
                                                        .copyWith(
                                                          color:
                                                              BuyV2Colors.navy,
                                                          height: 1,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              detail,
                                              maxLines: 2,
                                              overflow: TextOverflow.clip,
                                              style: sheetContext.buyMeta
                                                  .copyWith(height: 1.08),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                key: ValueKey('$ownerPrefix-sheet-close'),
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                tooltip: closeTooltip,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size.square(
                                    BuyV2Metrics.minimumTap,
                                  ),
                                  side: const BorderSide(
                                    color: BuyV2Colors.line,
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (publicPartner) ...[
                            _PublicStoreTruthPanel(
                              product: current,
                              facts: session.productFactsFor(current),
                              now: session.catalogueNow,
                              trust: storeTrust,
                              fulfilmentLabels: storeFulfilment,
                              onOrderForCollection: () {
                                if (session.beginStoreCollection(current.id)) {
                                  unawaited(
                                    openFullStoreCatalogue(sheetContext),
                                  );
                                }
                              },
                              onAskStore: onAskStore == null
                                  ? null
                                  : () => Navigator.of(
                                      sheetContext,
                                    ).pop('ask-store:${current.id}'),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (pagedPartner)
                            _PagedPublicStorePreview(
                              session: session,
                              product: current,
                              onOpenProduct: (product) => unawaited(
                                openStoreProduct(sheetContext, product),
                              ),
                            )
                          else if (previewProducts.isEmpty)
                            const _PublicStoreNoProductsState()
                          else
                            BuyV2ProgressiveProductGrid(
                              session: session,
                              products: previewProducts,
                              storageKey:
                                  '$ownerPrefix-catalogue-${brandOnly ? current.brand : current.seller}',
                              semanticLabel:
                                  '${brandOnly ? current.brand : current.seller} product catalogue',
                              laneCount: 1,
                              storeContext: !brandOnly,
                              onOpenProduct: (product) => unawaited(
                                openStoreProduct(sheetContext, product),
                              ),
                            ),
                          if (otherStores.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Other stores',
                              style: sheetContext.buyTitle.copyWith(
                                fontSize: 11.5,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Swipe for more relevant stores and delivery options',
                              style: sheetContext.buyMeta.copyWith(
                                fontSize: 8.5,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              key: ValueKey('$ownerPrefix-other-stores'),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    var index = 0;
                                    index < otherStores.length;
                                    index++
                                  )
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: index == otherStores.length - 1
                                            ? 0
                                            : 8,
                                      ),
                                      child: BuyV2CinematicCardReveal(
                                        stateKey:
                                            '$ownerPrefix-other-store-${otherStores[index].id}-motion',
                                        delay: Duration(
                                          milliseconds: index * 90,
                                        ),
                                        child: _RelatedStoreCard(
                                          key: ValueKey(
                                            '$ownerPrefix-other-store-${otherStores[index].id}',
                                          ),
                                          product: otherStores[index],
                                          branchAddress:
                                              otherStores[index].storeId == null
                                              ? null
                                              : session
                                                        .catalogueStore(
                                                          otherStores[index]
                                                              .storeId!,
                                                        )
                                                        ?.address ??
                                                    otherStores[index].origin,
                                          onTap: () {
                                            onStoreChanged?.call(
                                              otherStores[index],
                                            );
                                            unawaited(
                                              showBuyV2PartnerCatalogue(
                                                sheetContext,
                                                session,
                                                otherStores[index],
                                                onAskStore: (storeProduct) =>
                                                    Navigator.of(
                                                      sheetContext,
                                                    ).pop(
                                                      'ask-store:${storeProduct.id}',
                                                    ),
                                                onOpenProduct: onOpenProduct,
                                                onStoreChanged: onStoreChanged,
                                                onOpenStoreCart:
                                                    onOpenStoreCart,
                                                onOpenCart: () => Navigator.of(
                                                  sheetContext,
                                                ).pop('cart:'),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (session.countForDestination(current.destination) > 0)
                  BuyV2FiniteIncomingTransition(
                    key: const ValueKey('buy-store-cart-entrance-motion'),
                    stateKey: '$ownerPrefix-store-cart-${session.itemCount}',
                    child: BuyV2StoreCartBar(
                      session: session,
                      destination: current.destination,
                      onOpenCart: onOpenStoreCart == null
                          ? () => Navigator.of(sheetContext).pop('cart:')
                          : () => onOpenStoreCart(current),
                    ),
                  ),
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
      if (selectedProductId == 'cart:') {
        final openCart = onOpenCart;
        if (openCart == null) {
          session.openCart();
        } else {
          openCart();
        }
        return;
      }
      const askStorePrefix = 'ask-store:';
      if (selectedProductId.startsWith(askStorePrefix)) {
        final productId = selectedProductId.substring(askStorePrefix.length);
        final storeProduct = productId.isEmpty || productId == current.id
            ? current
            : session.findProduct(productId) ?? current;
        onAskStore?.call(storeProduct);
        return;
      }
      const storePrefix = 'store:';
      if (selectedProductId.startsWith(storePrefix)) {
        await showBuyV2PartnerCatalogue(
          context,
          session,
          session.product(selectedProductId.substring(storePrefix.length)),
          onAskStore: onAskStore,
          onStoreChanged: onStoreChanged,
          onOpenProduct: onOpenProduct,
          onOpenCart: onOpenCart,
          onOpenStoreCart: onOpenStoreCart,
        );
      } else {
        final product = session.product(selectedProductId);
        final handler = onOpenProduct;
        if (handler == null) {
          session.openProduct(product.id);
        } else if (await handler(product) && context.mounted) {
          session.openCart();
        }
      }
    }
  } finally {
    transitionController.dispose();
  }
}

List<String> _publicStoreFulfilmentLabels(
  BuyV2Session session,
  List<BuyV2Product> products,
) {
  final labels = <String>{};
  for (final product in products) {
    final facts = session.productFactsFor(product);
    final mode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    switch (mode) {
      case BuyV2FulfilmentMode.quickLocal:
        labels.add('Quick');
      case BuyV2FulfilmentMode.standardCourier:
        labels.add('Scheduled delivery');
      case BuyV2FulfilmentMode.bulkFreight:
        labels.add('Bulk delivery');
    }
    final service = facts.deliveryServiceLevel?.toLowerCase() ?? '';
    if (service.contains('pickup')) labels.add('Store pickup');
  }
  return List.unmodifiable(labels);
}

String _publicStoreLocality(String source) {
  final parts = source
      .split(RegExp(r'\s*(?:→|·)\s*'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.length >= 2) {
    final origin = parts.first;
    final destination = parts.last;
    final originIsJodhpur = origin.toLowerCase().startsWith('jodhpur');
    final destinationIsJodhpur = destination.toLowerCase().startsWith(
      'jodhpur',
    );
    if (destinationIsJodhpur) {
      return originIsJodhpur ? destination : origin;
    }
    return '$destination, $origin';
  }
  return source.trim();
}

String _publicProviderType(String source) {
  final value = source.trim().toLowerCase();
  if (value.contains('manufacturer')) return 'Manufacturer';
  if (value.contains('distributor')) return 'Distributor';
  if (value.contains('wholesaler')) return 'Wholesaler';
  if (value.contains('special')) return 'Speciality Store';
  if (value.contains('bulk')) return 'Bulk Seller';
  if (value.contains('retailer')) return 'Retailer';
  if (value.contains('shop') || value.contains('store')) return 'Retailer';
  return source
      .replaceFirst(RegExp(r'^Verified\s+', caseSensitive: false), '')
      .trim();
}

class _PublicStoreTruthPanel extends StatefulWidget {
  const _PublicStoreTruthPanel({
    required this.product,
    required this.facts,
    required this.now,
    required this.trust,
    required this.fulfilmentLabels,
    required this.onAskStore,
    required this.onOrderForCollection,
  });

  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final DateTime Function() now;
  final BuyV2MarketplaceTrustSnapshot trust;
  final List<String> fulfilmentLabels;
  final VoidCallback? onAskStore;
  final VoidCallback onOrderForCollection;

  @override
  State<_PublicStoreTruthPanel> createState() => _PublicStoreTruthPanelState();
}

class _PublicStoreTruthPanelState extends State<_PublicStoreTruthPanel>
    with WidgetsBindingObserver {
  late bool _showFulfilment;
  Timer? _collectionExpiry;

  bool get _showsCollection =>
      !widget.facts.stale &&
      widget.facts.productId == widget.product.id &&
      widget.facts.storeCollection?.isSupportedFor(
            widget.product.storeId,
            now: widget.now(),
          ) ==
          true;

  void _scheduleCollectionExpiry() {
    _collectionExpiry?.cancel();
    _collectionExpiry = null;
    if (!_showsCollection) return;
    final remaining = widget.facts.storeCollection!.validUntil.difference(
      widget.now(),
    );
    if (remaining <= Duration.zero) return;
    _collectionExpiry = Timer(remaining, () {
      if (!mounted) return;
      setState(() {});
      _scheduleCollectionExpiry();
    });
  }

  @override
  void initState() {
    super.initState();
    _showFulfilment =
        widget.facts.storeOperatingState != BuyV2StoreOperatingState.open;
    WidgetsBinding.instance.addObserver(this);
    _scheduleCollectionExpiry();
  }

  @override
  void didUpdateWidget(covariant _PublicStoreTruthPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCollectionExpiry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() {});
    _scheduleCollectionExpiry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _collectionExpiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final facts = widget.facts;
    final trust = widget.trust;
    final fulfilmentLabels = widget.fulfilmentLabels;
    final onAskStore = widget.onAskStore;
    final sourceLocation = trust.partnerLocation?.trim().isNotEmpty == true
        ? trust.partnerLocation!.trim()
        : product.origin.trim();
    final locality = _publicStoreLocality(sourceLocation);
    final providerType = _publicProviderType(product.sellerType);
    final fulfilmentIdentity = product.destination == BuyV2Destination.shop
        ? 'MoolSocial Fulfilment Store'
        : 'MoolSocial Fulfilment Partner';
    final askLabel = product.destination == BuyV2Destination.shop
        ? 'Ask store'
        : providerType == 'Manufacturer'
        ? 'Ask manufacturer'
        : 'Ask supplier';
    final addressConfirmed =
        trust.state == BuyV2MarketplaceTrustState.ready && locality.isNotEmpty;
    final (
      statusLabel,
      statusColor,
      statusSurface,
    ) = switch (facts.storeOperatingState) {
      BuyV2StoreOperatingState.open => (
        'Open',
        BuyV2Colors.green,
        BuyV2Colors.softGreen,
      ),
      BuyV2StoreOperatingState.closed => (
        facts.nextOpeningLabel?.trim().isNotEmpty == true
            ? 'Closed · Opens ${facts.nextOpeningLabel!.trim()}'
            : 'Closed',
        const Color(0xFFB64025),
        BuyV2Colors.softOrange,
      ),
      BuyV2StoreOperatingState.unknown => (
        'Store hours unavailable right now',
        BuyV2Colors.muted,
        BuyV2Colors.softBlue,
      ),
    };
    return Semantics(
      key: ValueKey('buy-public-store-truth-${product.id}'),
      container: true,
      label:
          '$fulfilmentIdentity. ${product.seller}. $providerType. '
          '${addressConfirmed ? 'Address confirmed. ' : ''}'
          '$locality. $statusLabel. ${fulfilmentLabels.join(', ')}',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: buyV2CardDecoration(
          color: BuyV2Colors.softBlue.withValues(alpha: .24),
          radius: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showsCollection)
              Container(
                key: const ValueKey('buy-public-store-collection-benefit'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: buyV2CardDecoration(
                  color: Colors.white,
                  radius: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                          color: BuyV2Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Order & Collect',
                            style: context.buyTitle.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order through MoolSocial and collect from the store when ready—less time spent shopping and waiting.',
                      style: context.buyBody.copyWith(height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const ValueKey('buy-public-store-order-collection'),
                      onPressed: widget.onOrderForCollection,
                      style: FilledButton.styleFrom(
                        backgroundColor: BuyV2Colors.navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, BuyV2Metrics.minimumTap),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Order for collection'),
                    ),
                  ],
                ),
              ),
            BuyV2AdaptiveIdentityRow(
              spacing: 6,
              leading: Semantics(
                button: true,
                label: _showFulfilment
                    ? 'Hide store status and delivery options'
                    : 'Show store status and delivery options',
                child: SizedBox(
                  key: const ValueKey('buy-public-store-fulfilment-toggle'),
                  width: BuyV2Metrics.minimumTap,
                  height: BuyV2Metrics.minimumTap,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showFulfilment = !_showFulfilment);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x33000080)),
                          ),
                          child: AnimatedSwitcher(
                            duration: BuyV2Motion.resolved(
                              context,
                              BuyV2Motion.stateChange,
                            ),
                            child: _showFulfilment
                                ? const Icon(
                                    Icons.expand_less_rounded,
                                    key: ValueKey(true),
                                    color: BuyV2Colors.navy,
                                    size: 18,
                                  )
                                : BuyV2DeliveryModeIcon(
                                    key: const ValueKey(false),
                                    artwork: buyV2DeliveryArtworkFor(
                                      product,
                                      fulfilmentMode: facts.fulfilmentMode,
                                    ),
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.seller,
                    key: const ValueKey('buy-public-store-name'),
                    style: context.buyBody.copyWith(
                      color: BuyV2Colors.navy,
                      fontSize: 12.5,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    fulfilmentIdentity,
                    key: const ValueKey('buy-public-store-badge'),
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.navy,
                      fontSize: 9.5,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    addressConfirmed
                        ? '$providerType · Address confirmed · $locality'
                        : '$providerType · $locality',
                    key: const ValueKey('buy-public-store-location'),
                    overflow: TextOverflow.clip,
                    style: context.buyMeta.copyWith(
                      fontSize: 9.5,
                      height: 1.08,
                    ),
                  ),
                ],
              ),
              trailing: onAskStore == null
                  ? null
                  : Semantics(
                      button: true,
                      label: askLabel,
                      child: SizedBox(
                        key: const ValueKey('buy-public-store-ask'),
                        width: 78,
                        height: BuyV2Metrics.minimumTap,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onAskStore,
                            borderRadius: BorderRadius.circular(9),
                            child: Center(
                              child: Container(
                                key: const ValueKey(
                                  'buy-public-store-ask-visible',
                                ),
                                height: 30,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0x33000080),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: BuyV2Colors.navy,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ask',
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
                        ),
                      ),
                    ),
            ),
            AnimatedSize(
              duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _showFulfilment
                  ? Padding(
                      key: const ValueKey(
                        'buy-public-store-fulfilment-details',
                      ),
                      padding: const EdgeInsets.only(top: 5),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            key: const ValueKey('buy-public-store-status'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusSurface,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  color: statusColor,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: context.buyMeta.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final label in fulfilmentLabels)
                            Container(
                              key: ValueKey(
                                'buy-public-store-fulfilment-'
                                '${label.toLowerCase().replaceAll(' ', '-')}',
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: const Color(0x33000080),
                                ),
                              ),
                              child: Text(
                                label,
                                style: context.buyMeta.copyWith(
                                  color: BuyV2Colors.navy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('buy-public-store-fulfilment-collapsed'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicStoreNoProductsState extends StatelessWidget {
  const _PublicStoreNoProductsState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('buy-public-store-no-products'),
      container: true,
      label: 'No products available right now.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: buyV2CardDecoration(color: Colors.white, radius: 16),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: BuyV2Colors.navy,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'No products available right now.',
              textAlign: TextAlign.center,
              style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class BuyV2StoreCartBar extends StatelessWidget {
  const BuyV2StoreCartBar({
    super.key,
    required this.session,
    required this.destination,
    required this.onOpenCart,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final itemCount = session.countForDestination(destination);
    final total = session.totalForDestination(destination);
    final itemLabel = itemCount == 1 ? 'item' : 'items';
    final acknowledgement = session.cartAcknowledgementForDestination(
      destination,
    );
    final visibleMessage = '$itemCount $itemLabel';
    final message = itemCount == 0
        ? 'Cart is empty'
        : acknowledgement == null
        ? '$visibleMessage in Cart'
        : '$acknowledgement · $visibleMessage';
    void activate() {
      HapticFeedback.selectionClick();
      onOpenCart();
    }

    const messageStyle = TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w900,
    );
    const totalStyle = TextStyle(
      color: Colors.white70,
      fontSize: 8,
      fontWeight: FontWeight.w700,
    );
    final totalText = buyV2Money(total);
    final messageSize = buyV2ValueTextSize(
      context,
      visibleMessage,
      messageStyle,
    );
    final totalSize = buyV2ValueTextSize(context, totalText, totalStyle);
    final valueWidth = messageSize.width > totalSize.width
        ? messageSize.width
        : totalSize.width;
    final height = (messageSize.height + totalSize.height + 16)
        .clamp(44.0, double.infinity)
        .toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (valueWidth + 55)
            .clamp(
              88.0,
              (constraints.maxWidth - 16).clamp(88.0, double.infinity),
            )
            .toDouble();
        return Align(
          alignment: Alignment.centerRight,
          heightFactor: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 3, 8, 4),
            child: Semantics(
              key: const ValueKey('buy-store-cart-bar'),
              container: true,
              button: true,
              liveRegion: true,
              label: '$message. $totalText. View Cart',
              onTap: activate,
              child: SizedBox(
                width: width,
                height: height,
                child: Material(
                  color: BuyV2Colors.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: BuyV2Colors.royal),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: activate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            acknowledgement == null
                                ? Icons.shopping_cart_outlined
                                : Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BuyV2FiniteValueTransition(
                                  key: const ValueKey(
                                    'buy-store-cart-feedback',
                                  ),
                                  stateKey: message,
                                  text: visibleMessage,
                                  ownerSize: Size(
                                    width - 55,
                                    messageSize.height,
                                  ),
                                  textAlign: TextAlign.start,
                                  duration: BuyV2Motion.contentChange,
                                  style: messageStyle,
                                ),
                                Text(
                                  totalText,
                                  key: const ValueKey('buy-store-cart-total'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: totalStyle,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 15,
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
      },
    );
  }
}

class _PagedPublicStorePreview extends StatefulWidget {
  const _PagedPublicStorePreview({
    required this.session,
    required this.product,
    required this.onOpenProduct,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  final ValueChanged<BuyV2Product> onOpenProduct;

  @override
  State<_PagedPublicStorePreview> createState() =>
      _PagedPublicStorePreviewState();
}

class _PagedPublicStorePreviewState extends State<_PagedPublicStorePreview> {
  late BuyV2CataloguePager<BuyV2Product> _pager;
  int _sequence = 0;
  String get _scope =>
      'store-preview-${widget.product.destination.name}-${widget.product.storeId}';
  BuyV2CatalogueQuery get _query => widget.session.catalogueQuery(
    storeId: widget.product.storeId,
    catalogueDestination: widget.product.destination,
    search: '',
    categoryId: 'all',
  );

  @override
  void initState() {
    super.initState();
    _attach();
  }

  void _attach() {
    _pager = widget.session.acquireCatalogueProducts(_scope);
    _pager.addListener(_changed);
    _schedule();
  }

  void _schedule() {
    final sequence = ++_sequence;
    Future<void>.microtask(() async {
      if (!mounted || sequence != _sequence) return;
      if (_pager.query != _query ||
          (_pager.page == null && !_pager.loading && _pager.message == null)) {
        await _pager.open(_query);
      }
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _detach(BuyV2Session session, String scope) {
    _sequence++;
    _pager.removeListener(_changed);
    session.releaseCatalogueProducts(scope);
  }

  @override
  void didUpdateWidget(covariant _PagedPublicStorePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.product.storeId != widget.product.storeId ||
        oldWidget.product.destination != widget.product.destination) {
      _detach(
        oldWidget.session,
        'store-preview-${oldWidget.product.destination.name}-${oldWidget.product.storeId}',
      );
      _attach();
    } else {
      _schedule();
    }
  }

  @override
  void dispose() {
    _detach(widget.session, _scope);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pager.query == _query ? _pager.page : null;
    final loading = _pager.query != _query || _pager.loading;
    final message = _pager.query == _query ? _pager.message : null;
    final products =
        page?.items.take(6).toList(growable: false) ?? const <BuyV2Product>[];
    return Column(
      key: ValueKey('buy-store-source-preview-${widget.product.storeId}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        if (message != null)
          _CataloguePageNotice(
            title: 'Store products could not load',
            detail: message,
            action: 'Try products again',
            onAction: loading ? null : _pager.retry,
          ),
        if (!loading && message == null && products.isEmpty)
          const _PublicStoreNoProductsState(),
        if (products.isNotEmpty)
          BuyV2ProgressiveProductGrid(
            session: widget.session,
            products: products,
            storageKey: _scope,
            semanticLabel: '${widget.product.seller} product catalogue preview',
            laneCount: 1,
            storeContext: true,
            onOpenProduct: widget.onOpenProduct,
          ),
      ],
    );
  }
}

class _PagedFullStoreCatalogue extends StatefulWidget {
  const _PagedFullStoreCatalogue({
    required this.session,
    required this.product,
    required this.onOpenProduct,
    required this.onClose,
  });
  final BuyV2Session session;
  final BuyV2Product product;
  final ValueChanged<BuyV2Product> onOpenProduct;
  final VoidCallback onClose;

  @override
  State<_PagedFullStoreCatalogue> createState() =>
      _PagedFullStoreCatalogueState();
}

class _PagedFullStoreCatalogueState extends State<_PagedFullStoreCatalogue> {
  late TextEditingController _search;
  final _searchFocus = FocusNode();
  String _category = 'all';
  String get _scope =>
      'store-${widget.product.destination.name}-${widget.product.storeId}';

  @override
  void initState() {
    super.initState();
    final retained = widget.session.retainedCatalogueQuery(_scope);
    final sameStore = retained?.storeId == widget.product.storeId;
    _category = sameStore ? retained?.categoryId ?? 'all' : 'all';
    _search = TextEditingController(
      text: sameStore ? retained?.query ?? '' : '',
    );
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _chooseCategory() async {
    _searchFocus.unfocus();
    final categories = widget.session.categoriesFor(widget.product.destination);
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .8,
        child: BuyV2VerticalScrollIndicator(
          child: ListView(
            key: const ValueKey('buy-store-category-list'),
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              16 + BuyV2AddressSheetMotion.resolveBottomSafeInset(sheetContext),
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Store categories', style: context.buyTitle),
                  ),
                  IconButton(
                    tooltip: 'Close store categories',
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ListTile(
                key: const ValueKey('buy-store-category-all'),
                selected: _category == 'all',
                title: const Text('All products'),
                onTap: () => Navigator.of(sheetContext).pop('all'),
              ),
              for (final category in categories.where(
                (value) => value.id != 'all',
              ))
                ListTile(
                  key: ValueKey('buy-store-category-${category.id}'),
                  selected: _category == category.id,
                  title: Text(category.label),
                  onTap: () => Navigator.of(sheetContext).pop(category.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    _searchFocus.unfocus();
    if (choice != null) setState(() => _category = choice);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final store = widget.session.catalogueStore(product.storeId!);
    final category = widget.session
        .categoriesFor(product.destination)
        .where((value) => value.id == _category)
        .firstOrNull;
    return BuyV2PagedProductCatalogue(
      session: widget.session,
      scopeKey: _scope,
      storeContext: true,
      query: widget.session.catalogueQuery(
        storeId: product.storeId,
        catalogueDestination: product.destination,
        search: _search.text,
        categoryId: _category,
      ),
      onOpenProduct: (product) {
        _searchFocus.unfocus();
        widget.onOpenProduct(product);
      },
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuyV2AdaptiveIdentityRow(
              leading: const Icon(
                Icons.storefront_outlined,
                color: BuyV2Colors.navy,
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store?.name ?? product.seller,
                    key: const ValueKey('buy-paged-store-name'),
                    style: context.buyTitle.copyWith(fontSize: 16),
                  ),
                  Text(
                    store?.address ?? product.origin,
                    style: context.buyMeta,
                  ),
                ],
              ),
              trailing: IconButton.outlined(
                key: const ValueKey('buy-paged-store-close'),
                tooltip: 'Close full store catalogue',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Search this store',
                    child: TextField(
                      key: const ValueKey('buy-store-product-search'),
                      controller: _search,
                      focusNode: _searchFocus,
                      maxLength: 80,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText:
                            MediaQuery.textScalerOf(context).scale(1) > 1.25
                            ? 'Search'
                            : 'Search this store',
                        counterText: '',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                key: const ValueKey(
                                  'buy-store-product-search-clear',
                                ),
                                tooltip: 'Clear store search',
                                onPressed: () => setState(_search.clear),
                                icon: const Icon(Icons.close_rounded),
                              ),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _searchFocus.unfocus(),
                      onTapOutside: (_) => _searchFocus.unfocus(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  selected: _category != 'all',
                  child: _CatalogueChromeAction(
                    key: const ValueKey('buy-store-category-control'),
                    label:
                        'Choose store category. Current category '
                        '${_category == 'all' ? 'All products' : category?.label ?? 'Choose category'}',
                    tooltip:
                        'Store categories · '
                        '${_category == 'all' ? 'All products' : category?.label ?? 'Choose category'}',
                    icon: Icons.grid_view_rounded,
                    active: _category != 'all',
                    onTap: _chooseCategory,
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

Future<String?> _showBuyV2FullStoreCatalogue(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product current,
  List<BuyV2Product> products,
  String ownerPrefix, {
  Future<bool> Function(BuyV2Product product)? onOpenProduct,
  VoidCallback? onOpenCart,
}) {
  Future<void> openProduct(
    BuildContext sheetContext,
    BuyV2Product product,
  ) async {
    final handler = onOpenProduct;
    if (handler == null) {
      Navigator.of(sheetContext).pop(product.id);
      return;
    }
    final openCart = await handler(product);
    if (openCart && sheetContext.mounted) {
      Navigator.of(sheetContext).pop('cart:');
    }
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FractionallySizedBox(
          key: ValueKey('$ownerPrefix-full-catalogue-sheet'),
          heightFactor: .98,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child:
                      session.pagedCatalogueEnabled && current.storeId != null
                      ? _PagedFullStoreCatalogue(
                          session: session,
                          product: current,
                          onOpenProduct: (product) =>
                              unawaited(openProduct(sheetContext, product)),
                          onClose: () => Navigator.of(sheetContext).pop(),
                        )
                      : ListView(
                          key: ValueKey('$ownerPrefix-full-catalogue-list'),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                          children: [
                            BuyV2AdaptiveIdentityRow(
                              spacing: 10,
                              leading: const SizedBox.square(
                                dimension: 44,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: BuyV2Colors.softOrange,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: BuyV2Colors.navy,
                                  ),
                                ),
                              ),
                              body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    current.seller,
                                    style: sheetContext.buyTitle.copyWith(
                                      fontSize: 18,
                                    ),
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
                              trailing: IconButton.outlined(
                                key: ValueKey(
                                  '$ownerPrefix-full-catalogue-close',
                                ),
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                tooltip: 'Close full store catalogue',
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                            const SizedBox(height: 10),
                            BuyV2ProgressiveProductGrid(
                              session: session,
                              products: products,
                              storageKey:
                                  '$ownerPrefix-full-catalogue-${current.seller}',
                              semanticLabel:
                                  '${current.seller} full product catalogue',
                              laneCount: products.length >= 6 ? 2 : 1,
                              fitSmallCatalogue:
                                  current.destination ==
                                      BuyV2Destination.shop ||
                                  current.destination ==
                                      BuyV2Destination.wholesale,
                              storeContext: true,
                              onOpenProduct: (product) =>
                                  unawaited(openProduct(sheetContext, product)),
                            ),
                          ],
                        ),
                ),
                if (session.countForDestination(current.destination) > 0)
                  BuyV2FiniteIncomingTransition(
                    stateKey:
                        '$ownerPrefix-full-catalogue-cart-${session.itemCount}',
                    child: BuyV2StoreCartBar(
                      session: session,
                      destination: current.destination,
                      onOpenCart:
                          onOpenCart ??
                          () => Navigator.of(sheetContext).pop('cart:'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RelatedStoreCard extends StatelessWidget {
  const _RelatedStoreCard({
    required this.product,
    required this.onTap,
    this.branchAddress,
    super.key,
  });

  final BuyV2Product product;
  final VoidCallback onTap;
  final String? branchAddress;

  @override
  Widget build(BuildContext context) {
    final accessibleText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final providerType = _sellerTypeLabel(product.sellerType);
    final identity = product.destination == BuyV2Destination.shop
        ? 'MoolSocial Fulfilment Store'
        : 'MoolSocial Fulfilment Partner';
    final fulfilmentMode = buyV2CatalogueFulfilmentModeFor(product);
    final delivery = switch (fulfilmentMode) {
      BuyV2FulfilmentMode.quickLocal => 'Quick',
      BuyV2FulfilmentMode.standardCourier => _compactDeliveryPromise(
        product.deliveryPromise,
      ),
      BuyV2FulfilmentMode.bulkFreight =>
        'Bulk delivery · ${_compactDeliveryPromise(product.deliveryPromise)}',
    };
    final sellerLabel = Text(
      product.seller,
      style: context.buyBody.copyWith(
        color: BuyV2Colors.navy,
        fontSize: 11.5,
        height: 1.05,
        fontWeight: FontWeight.w900,
      ),
    );
    Widget headerIcon(IconData icon) => Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0x33000080)),
      ),
      child: Icon(icon, color: BuyV2Colors.navy, size: 16),
    );
    return BuyV2IntentDepth(
      spatial: false,
      child: SizedBox(
        width: accessibleText ? 208 : 196,
        child: Material(
          key: ValueKey('buy-related-store-surface-${product.id}'),
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: BuyV2Colors.navy.withValues(alpha: .1),
            highlightColor: BuyV2Colors.navy.withValues(alpha: .05),
            child: Container(
              key: ValueKey('buy-related-store-card-${product.id}'),
              constraints: BoxConstraints(
                minHeight: accessibleText ? 190 : 145,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(color: const Color(0x40000080)),
                boxShadow: [
                  BoxShadow(
                    color: BuyV2Colors.navy.withValues(alpha: .09),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: ValueKey('buy-related-store-header-${product.id}'),
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            headerIcon(Icons.storefront_outlined),
                            if (accessibleText)
                              const Spacer()
                            else ...[
                              const SizedBox(width: 8),
                              Expanded(child: sellerLabel),
                              const SizedBox(width: 6),
                            ],
                            headerIcon(Icons.arrow_forward_rounded),
                          ],
                        ),
                        if (accessibleText) ...[
                          const SizedBox(height: 4),
                          sellerLabel,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$identity · $providerType',
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.navy,
                      fontSize: 9.5,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (branchAddress?.trim().isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 3),
                      child: Text(
                        branchAddress!,
                        key: ValueKey('buy-related-store-branch-${product.id}'),
                        style: context.buyMeta.copyWith(
                          fontSize: 9.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 1),
                  Text(
                    '${product.title} · ${product.pack}',
                    style: context.buyMeta.copyWith(
                      color: BuyV2Colors.ink,
                      fontSize: 9.5,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Wrap(
                    spacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        buyV2Money(product.price),
                        style: context.buyBody.copyWith(
                          color: BuyV2Colors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(product.unitPrice, style: context.buyMeta),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      BuyV2DeliveryModeIcon(
                        artwork: buyV2DeliveryArtworkFor(product),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          delivery,
                          style: context.buyMeta.copyWith(
                            color: BuyV2Colors.navy,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                          : BuyV2VerticalScrollIndicator(
                              key: ValueKey('buy-saved-scroll-$ownerKey'),
                              child: ListView.separated(
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
                          : BuyV2VerticalScrollIndicator(
                              key: ValueKey('buy-recent-scroll-$ownerKey'),
                              child: ListView.separated(
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Semantics(
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
                            style: const TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.pack} · ${buyV2Money(facts.price)}',
                            style: context.buyMeta,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            buyV2BuyerDeliveryPromise(facts),
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
            );
            final add = ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 76,
                minHeight: BuyV2Metrics.minimumTap,
              ),
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
                    minimumSize: const Size(76, BuyV2Metrics.minimumTap),
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
            // Keep purchase facts readable beside the image. Move the action
            // below them when narrow or enlarged text needs the row width.
            if (constraints.maxWidth /
                    MediaQuery.textScalerOf(context).scale(1) <
                330) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  details,
                  const SizedBox(height: 4),
                  Align(alignment: Alignment.centerRight, child: add),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 7),
                add,
              ],
            );
          },
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
              'No saved products yet',
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
              label: 'Open ${product.title}, ${product.pack}',
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
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.pack} · ${buyV2Money(product.price)}',
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
    required this.session,
    required this.onClose,
    required this.onSeeProducts,
    required this.onAddToCart,
  });

  final BuyV2Session session;
  final VoidCallback onClose;
  final VoidCallback onSeeProducts;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final plan = session.monthlyBasketPlan;
    final complete = plan.length == 12;
    final subtotal = plan.fold<int>(0, (total, line) => total + line.total);
    final quickProducts = plan
        .where(
          (line) =>
              session.fulfilmentModeFor(line.product) ==
              BuyV2FulfilmentMode.quickLocal,
        )
        .length;
    final scheduledProducts = plan
        .where(
          (line) =>
              session.fulfilmentModeFor(line.product) ==
              BuyV2FulfilmentMode.standardCourier,
        )
        .length;
    final compactActions =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final seeProducts = OutlinedButton.icon(
      key: const ValueKey('buy-household-see-products'),
      onPressed: plan.isEmpty ? null : onSeeProducts,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(BuyV2Metrics.minimumTap),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      icon: const Icon(Icons.grid_view_rounded, size: 18),
      label: const Text('View basket products'),
    );
    final addToCart = FilledButton.icon(
      key: const ValueKey('buy-household-add-to-cart'),
      onPressed: session.monthlyBasketCanAdd ? onAddToCart : null,
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
                      Text(
                        'HOUSEHOLD BASKET',
                        style: context.buyMeta.copyWith(
                          color: BuyV2Colors.navy,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complete
                            ? 'Product subtotal ${buyV2Money(subtotal)}'
                            : 'Basket prices are unavailable right now',
                        key: const ValueKey('buy-household-subtotal'),
                        style: context.buyBody.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HouseholdBasketFact(
                            icon: Icons.speed_rounded,
                            label: 'Quick · $quickProducts products',
                          ),
                          _HouseholdBasketFact(
                            icon: Icons.schedule_rounded,
                            label: 'Scheduled · $scheduledProducts products',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        session.monthlyBasketCanAdd
                            ? 'At current product prices. Any discounts and delivery charges are confirmed at Checkout. Only missing packs are added to reach this basket.'
                            : session.checkoutRequiresResolution
                            ? 'Check the current payment before changing your Cart.'
                            : 'Some basket products are unavailable. Review products before adding.',
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
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: BuyV2Colors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
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
  final days = RegExp(
    r'(?:(dispatch|delivery)\s+)?(?:in|within)\s+(one|two|three|\d+)\s+days?',
    caseSensitive: false,
  ).firstMatch(value);
  if (days != null) {
    final count = switch (days.group(2)!.toLowerCase()) {
      'one' => '1',
      'two' => '2',
      'three' => '3',
      final value => value,
    };
    final action = days.group(1)?.toLowerCase() == 'dispatch'
        ? 'Dispatch'
        : 'Delivery';
    return '$action · $count ${count == '1' ? 'day' : 'days'}';
  }
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
      return BuyV2CatalogueAvailabilityView(session: session);
    }
    final products = savedOnly
        ? session.visibleSavedProducts
        : session.catalogueSaleTypeProducts;
    final showPromotions =
        !savedOnly &&
        session.query.isEmpty &&
        session.selectedCategoryId == 'all' &&
        session.activeShoppingIntent == null;
    if (products.isEmpty) {
      final savedCollectionEmpty =
          savedOnly && session.savedCountFor(session.destination) == 0;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: BuyV2CartAvoidanceRegion(
            key: const ValueKey('buy-empty-content-protection'),
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
                  savedCollectionEmpty
                      ? 'No saved products yet'
                      : savedOnly
                      ? 'No matching saved products'
                      : 'No matching products',
                  style: context.buyTitle.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  savedCollectionEmpty
                      ? 'Save products while browsing to find them here.'
                      : savedOnly
                      ? 'Your products are still saved. Clear search and filters to see them.'
                      : session.query.trim().isNotEmpty
                      ? 'Check the product code or search by product name.'
                      : 'Try another category or clear the filter.',
                  textAlign: TextAlign.center,
                  style: context.buyMeta,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    if (savedCollectionEmpty) {
                      onShowAll();
                    } else {
                      session.updateQuery('');
                      session.chooseFilter(null);
                      session.chooseCategory('all');
                      session.clearDiscoveryRefinements();
                    }
                  },
                  child: Text(
                    savedCollectionEmpty
                        ? 'Show all products'
                        : savedOnly
                        ? 'Clear search and filters'
                        : session.query.trim().isNotEmpty
                        ? session.hasNarrowedProductSearchScope
                              ? 'Clear search and filters'
                              : 'Clear search'
                        : 'Clear filters',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _QuantityAwareGridLayout(
      session: session,
      products: products,
      builder: (context, constraints, quantityWidth) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        const compactCards = true;
        final layout = _resolveCompactProductGridLayout(
          constraints: constraints,
          accessibleText: accessibleText,
          textScale: textScale,
          savedOnly: savedOnly,
          cartQuantityWidth: quantityWidth,
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
            '-${session.saleTypeSignature}-${savedOnly ? 'saved' : 'all'}',
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
                  laneCount: savedOnly || gridProducts.length <= layout.columns
                      ? 1
                      : null,
                  savedContext: savedOnly,
                ),
              ),
          ],
        );
      },
    );
  }
}

class BuyV2CatalogueAvailabilityView extends StatelessWidget {
  const BuyV2CatalogueAvailabilityView({
    super.key,
    required this.session,
    this.title,
    this.detail,
    this.loading,
    this.retryAvailable = true,
    this.onReturn,
    this.returnLabel = 'Back',
  });

  final BuyV2Session session;
  final String? title;
  final String? detail;
  final bool? loading;
  final bool retryAvailable;
  final VoidCallback? onReturn;
  final String returnLabel;

  @override
  Widget build(BuildContext context) {
    final loading =
        this.loading ??
        session.commerceLoadState == BuyV2CommerceLoadState.loading;
    final offline = session.commerceLoadState == BuyV2CommerceLoadState.offline;
    final title =
        this.title ??
        (loading
            ? 'Opening Shop'
            : offline
            ? 'Shop could not refresh'
            : 'Shop is unavailable right now');
    final detail =
        this.detail ??
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
              if (!loading && retryAvailable) ...[
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: BuyV2Metrics.minimumTap,
                  ),
                  child: FilledButton.icon(
                    key: const ValueKey('buy-catalogue-retry'),
                    onPressed: session.retryCommerce,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                  ),
                ),
              ],
              if (onReturn != null) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: BuyV2Metrics.minimumTap,
                  ),
                  child: OutlinedButton(
                    key: const ValueKey('buy-procurement-return'),
                    onPressed: onReturn,
                    child: Text(returnLabel, textAlign: TextAlign.center),
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
    final expandedHeader = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final clearAction = BuyV2CartAvoidanceRegion(
      child: TextButton(
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
          minimumSize: const Size(44, 44),
          visualDensity: VisualDensity.compact,
          textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
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
    );

    return BuyV2CartAvoidanceRegion(
      child: Semantics(
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
                  if (!expandedHeader) clearAction,
                ],
              ),
              if (expandedHeader)
                Align(alignment: Alignment.centerRight, child: clearAction),
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
                    onPressed: () =>
                        showBuyV2PrescriptionSheet(context, session),
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
      child: SafeArea(
        top: false,
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final keep = OutlinedButton(
                    key: const ValueKey('buy-saved-keep'),
                    onPressed: onKeep,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Keep saved',
                      textAlign: TextAlign.center,
                    ),
                  );
                  final clear = FilledButton(
                    key: const ValueKey('buy-saved-confirm-clear'),
                    onPressed: onClear,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB3261E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Clear list',
                      textAlign: TextAlign.center,
                    ),
                  );
                  final stackActions =
                      constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(15) > 20;
                  return stackActions
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [keep, const SizedBox(height: 10), clear],
                        )
                      : Row(
                          children: [
                            Expanded(child: keep),
                            const SizedBox(width: 10),
                            Expanded(child: clear),
                          ],
                        );
                },
              ),
            ],
          ),
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
    this.fitSmallCatalogue = false,
    this.savedContext = false,
    this.onOpenProduct,
    this.storeContext = false,
    this.vertical = false,
    this.productSupplement,
    this.beforeCartChange,
    this.initialAddQuantity,
    this.beforeSave,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final String storageKey;
  final String semanticLabel;
  final int? laneCount;

  /// A complete small store catalogue uses rows instead of hiding a last SKU
  /// beyond an apparently complete horizontal row. Larger inventories retain
  /// the bounded progressive browsing behaviour.
  final bool fitSmallCatalogue;
  final bool savedContext;
  final ValueChanged<BuyV2Product>? onOpenProduct;
  final bool storeContext;
  final bool vertical;
  final Widget Function(BuyV2Product)? productSupplement;
  final Future<bool> Function(BuyV2Product, int)? beforeCartChange;
  final int? initialAddQuantity;
  final bool Function(BuyV2Product)? beforeSave;

  @override
  Widget build(BuildContext context) {
    return _QuantityAwareGridLayout(
      session: session,
      products: products,
      builder: (context, constraints, quantityWidth) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        final layout = _resolveCompactProductGridLayout(
          constraints: constraints,
          accessibleText: accessibleText,
          textScale: textScale,
          denseStore: storeContext,
          cartQuantityWidth: quantityWidth,
        );
        if (vertical) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Wrap(
              key: ValueKey('buy-vertical-product-grid-$storageKey'),
              spacing: 7,
              runSpacing: 10,
              children: [
                for (final product in products)
                  SizedBox(
                    key: ValueKey('buy-product-compare-${product.id}'),
                    width: layout.cardWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: layout.tileHeight,
                          child: BuyV2ProductCard(
                            session: session,
                            product: product,
                            compact: true,
                            savedContext: savedContext,
                            storeContext: storeContext,
                            onOpenProduct: onOpenProduct,
                            initialAddQuantity: initialAddQuantity,
                            beforeSave: beforeSave == null
                                ? null
                                : () => beforeSave!(product),
                            beforeCartChange: beforeCartChange == null
                                ? null
                                : (quantity) =>
                                      beforeCartChange!(product, quantity),
                          ),
                        ),
                        if (productSupplement != null)
                          productSupplement!(product),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }
        final fittedRows =
            fitSmallCatalogue &&
                products.isNotEmpty &&
                products.length <= _HorizontalProductGridState._pageSize
            ? (products.length / layout.columns).ceil()
            : null;
        return _HorizontalProductGrid(
          session: session,
          products: products,
          cardWidth: layout.cardWidth,
          tileHeight: layout.tileHeight,
          storageKey: storageKey,
          compact: true,
          laneCount:
              fittedRows ??
              laneCount ??
              (products.length <= layout.columns ? 1 : null),
          verticalCatalogueColumns: fittedRows != null ? layout.columns : null,
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
  required double textScale,
  bool savedOnly = false,
  bool denseStore = false,
  bool scrollIndicatorInset = false,
  double cartQuantityWidth = 0,
}) {
  // The founder-approved Shop and Wholesale rhythm keeps three products
  // visible at normal text scale. Enlarged accessibility text uses two cards
  // so type and actions can grow without clipping.
  // The page scroller reserves 8px inside the same viewport. Keep that gutter
  // out of the breakpoint calculation, while card widths use the real space.
  final viewportWidth = constraints.maxWidth + (scrollIndicatorInset ? 8 : 0);
  final columns = savedOnly
      ? viewportWidth >= 320
            ? 2
            : 1
      : accessibleText && viewportWidth < 460
      ? 2
      : viewportWidth >= 320
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
      : denseStore
      ? accessibleText
            ? constraints.maxWidth < 360
                  ? 270.0
                  : 260.0
            : columns == 3
            ? 212.0
            : 216.0
      : accessibleText
      ? constraints.maxWidth < 360
            ? 300.0
            : 288.0
      : columns == 3
      ? 240.0
      : 238.0;
  final enlargedTextHeight =
      (textScale - 1.4).clamp(0.0, double.infinity) * 160;
  return (
    columns: columns,
    cardWidth: cardWidth,
    tileHeight:
        tileHeight +
        enlargedTextHeight +
        (cartQuantityWidth > 0 &&
                _gridQuantityStacks(cardWidth - 12, cartQuantityWidth)
            ? _gridQuantityLabelHeight(textScale)
            : 0),
  );
}

double _gridQuantityLabelHeight(double scale) =>
    (scale * 11 * 1.2 * 2 + 2).clamp(44.0, double.infinity).toDouble();

const _gridQuantityStyle = TextStyle(
  color: BuyV2Colors.navy,
  fontSize: 11,
  height: 1.2,
  fontWeight: FontWeight.w900,
);

bool _gridQuantityStacks(double width, double valueWidth) =>
    width < 88 + (valueWidth + 16).clamp(44.0, double.infinity);

double _gridMaximumQuantityWidth(
  BuildContext context,
  BuyV2Session session,
  List<BuyV2Product> products,
) {
  var width = 0.0;
  for (final product in products) {
    final quantity = session.quantityFor(product.id);
    if (quantity == 0) continue;
    final measured = buyV2ValueTextSize(
      context,
      '$quantity',
      _gridQuantityStyle,
    ).width;
    if (measured > width) width = measured;
  }
  return width;
}

class _QuantityAwareGridLayout extends StatefulWidget {
  const _QuantityAwareGridLayout({
    required this.session,
    required this.products,
    required this.builder,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final Widget Function(BuildContext, BoxConstraints, double) builder;

  @override
  State<_QuantityAwareGridLayout> createState() =>
      _QuantityAwareGridLayoutState();
}

class _QuantityAwareGridLayoutState extends State<_QuantityAwareGridLayout> {
  late List<String> _productIds;
  double _largestQuantityWidth = 0;
  double? _viewportWidth;
  double? _textScale;

  @override
  void initState() {
    super.initState();
    _productIds = widget.products.map((product) => product.id).toList();
  }

  @override
  void didUpdateWidget(covariant _QuantityAwareGridLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.products.map((product) => product.id).toList();
    if (oldWidget.session != widget.session || !listEquals(_productIds, ids)) {
      _largestQuantityWidth = 0;
    }
    _productIds = ids;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      if (_viewportWidth != constraints.maxWidth || _textScale != scale) {
        _largestQuantityWidth = 0;
        _viewportWidth = constraints.maxWidth;
        _textScale = scale;
      }
      final measured = _gridMaximumQuantityWidth(
        context,
        widget.session,
        widget.products,
      );
      if (measured > _largestQuantityWidth) _largestQuantityWidth = measured;
      // Removing a quantity row must not shrink scroll extent under a buyer's
      // finger. The product image uses the retained card space. A new product
      // scope or viewport starts with its own compact geometry.
      return widget.builder(context, constraints, _largestQuantityWidth);
    },
  );
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
    this.verticalCatalogueColumns,
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
  final int? verticalCatalogueColumns;
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
    final verticalColumns = widget.verticalCatalogueColumns;
    int laneItemCount(int laneIndex) {
      if (verticalColumns != null) {
        final remaining = products.length - laneIndex * verticalColumns;
        return remaining < verticalColumns ? remaining : verticalColumns;
      }
      return (products.length - laneIndex + resolvedLaneCount - 1) ~/
          resolvedLaneCount;
    }

    var cardWidth = widget.cardWidth;
    if (widget.compact) {
      for (final product in products) {
        if (product.destination != BuyV2Destination.medicine) continue;
        final facts = widget.session.productFactsFor(product);
        for (final field in [
          (
            text: product.title,
            style: const TextStyle(
              fontSize: 10,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
            insets: 14.0,
          ),
          (
            text: product.pack,
            style: context.buyMeta.copyWith(fontSize: 8.5, height: 1.05),
            insets: 14.0,
          ),
          (
            text:
                '${facts.partner} · ${_compactDeliveryPromise(facts.deliveryPromise)}',
            style: const TextStyle(
              fontSize: 8,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
            insets: 36.0,
          ),
        ]) {
          for (final word in field.text.split(RegExp(r'\s+'))) {
            final measure = TextPainter(
              text: TextSpan(
                text: word,
                style: DefaultTextStyle.of(context).style.merge(field.style),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final needed = (measure.width + field.insets).ceilToDouble();
            if (needed > cardWidth) cardWidth = needed;
            measure.dispose();
          }
        }
      }
    }
    var medicalPromiseReserve = 0.0;
    if (widget.compact) {
      final promiseStyle = DefaultTextStyle.of(context).style.merge(
        const TextStyle(fontSize: 8, height: 1.1, fontWeight: FontWeight.w800),
      );
      for (final product in products) {
        if (product.destination != BuyV2Destination.medicine) continue;
        final facts = widget.session.productFactsFor(product);
        final measure = TextPainter(
          text: TextSpan(
            text:
                '${facts.partner} · ${_compactDeliveryPromise(facts.deliveryPromise)}',
            style: promiseStyle,
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: (cardWidth - 36).clamp(1.0, double.infinity));
        // Long pharmacy identity and delivery text needs space beyond a
        // two-line promise, without shrinking the image or clipping actions.
        final promiseExtra = (measure.height - measure.preferredLineHeight * 2)
            .clamp(0.0, double.infinity)
            .ceilToDouble();
        final title = TextPainter(
          text: TextSpan(
            text: product.title,
            style: DefaultTextStyle.of(context).style.merge(
              const TextStyle(
                fontSize: 10,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: (cardWidth - 14).clamp(1.0, double.infinity));
        final titleExtra = (title.height - title.preferredLineHeight * 3)
            .clamp(0.0, double.infinity)
            .ceilToDouble();
        final extra = promiseExtra + titleExtra;
        if (extra > medicalPromiseReserve) medicalPromiseReserve = extra;
        title.dispose();
        measure.dispose();
      }
    }
    final tileHeight = widget.tileHeight + medicalPromiseReserve;
    return Semantics(
      key: const ValueKey('buy-horizontal-product-grid'),
      container: true,
      liveRegion: true,
      label:
          '${widget.semanticLabel}. Showing ${products.length} of '
          '${widget.products.length} ${widget.products.length == 1 ? 'product' : 'products'}.'
          '${verticalColumns != null
              ? resolvedLaneCount > 1
                    ? ' Scroll up or down to browse.'
                    : ''
              : widget.products.length > 1
              ? ' Swipe left or right to browse.'
              : ''}',
      child: SizedBox(
        key: ValueKey('buy-progressive-product-count-${widget.storageKey}'),
        height: (tileHeight * resolvedLaneCount) + 14,
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
                        'Product row ${laneIndex + 1} of $resolvedLaneCount.',
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
                        itemCount: laneItemCount(laneIndex),
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (context, index) {
                          final productIndex = verticalColumns != null
                              ? laneIndex * verticalColumns + index
                              : (index * resolvedLaneCount) + laneIndex;
                          return SizedBox(
                            width: cardWidth,
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final accessibleText = textScale > 1.25;
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
          detail: 'Compare wholesale packs for your business',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 19) / 2;
        if (accessibleText ||
            cards.any((card) => !card.fitsTextWidth(context, cardWidth))) {
          return Padding(
            key: const ValueKey('buy-catalogue-promotions'),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  if (index > 0) const SizedBox(height: 7),
                  BuyV2CartAvoidanceRegion(child: cards[index]),
                ],
              ],
            ),
          );
        }
        return SizedBox(
          key: const ValueKey('buy-catalogue-promotions'),
          height:
              (accessibleText ? 164.0 : 148.0) +
              (textScale - 1.4).clamp(0.0, double.infinity) * 120,
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
                  Expanded(
                    child: BuyV2CartAvoidanceRegion(child: cards[index]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
    final viewport = MediaQuery.sizeOf(context);
    final shortLandscape =
        viewport.width > viewport.height && viewport.height <= 480;
    final cardWidth = accessibleText && shortLandscape
        ? (178 * MediaQuery.textScalerOf(context).scale(1))
              .clamp(1.0, (viewport.width - 28).clamp(1.0, double.infinity))
              .toDouble()
        : accessibleText
        ? 178.0
        : 168.0;
    final titleStyle = context.buyTitle.copyWith(fontSize: 15);
    final hintStyle = context.buyMeta.copyWith(
      color: BuyV2Colors.navy,
      fontSize: 8,
      fontWeight: FontWeight.w800,
    );
    final titleHeight = buyV2ValueTextSize(context, title, titleStyle).height;
    final hintHeight =
        buyV2ValueTextSize(
          context,
          'Swipe to explore',
          hintStyle,
        ).height.clamp(14.0, double.infinity) +
        8;
    final rowHeight = titleHeight > hintHeight ? titleHeight : hintHeight;
    // A wrapped heading grows the section, not at the expense of product media.
    final titleReserve = products.fold(0.0, (height, product) {
      final extra = _FeaturedProductCard.titleExpansion(
        context,
        product,
        cardWidth,
      );
      return height > extra ? height : extra;
    });
    final cardLaneHeight =
        (accessibleText ? 365.0 : 285.0) - rowHeight - 12 + titleReserve;
    return Column(
      key: const ValueKey('buy-featured-products'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 7, 9, 5),
          child: BuyV2CartAvoidanceRegion(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: titleStyle),
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
                            Text('Swipe to explore', style: hintStyle),
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
        ),
        SizedBox(
          key: PageStorageKey('buy-featured-${session.destination.name}'),
          height: cardLaneHeight,
          child: ListView.separated(
            key: const ValueKey('buy-featured-product-list'),
            padding: const EdgeInsets.fromLTRB(7, 0, 12, 8),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: _FeaturedProductCard(
                session: session,
                product: products[index],
              ),
            ),
          ),
        ),
      ],
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
    final cardHeight = products.fold(accessibleText ? 122.0 : 102.0, (
      height,
      product,
    ) {
      final needed = _RecentlyViewedCard.minimumHeight(
        context,
        session,
        product,
        accessibleText,
      );
      return height > needed ? height : needed;
    });
    return Column(
      key: const ValueKey('buy-recently-viewed'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 2, 4, 2),
          child: BuyV2CartAvoidanceRegion(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recently viewed',
                        key: const ValueKey('buy-recently-viewed-heading'),
                        maxLines: accessibleText ? null : 1,
                        overflow: accessibleText
                            ? TextOverflow.clip
                            : TextOverflow.ellipsis,
                        style: context.buyTitle.copyWith(fontSize: 14),
                      ),
                      Text(
                        'Continue with the exact pack you viewed',
                        key: const ValueKey('buy-recently-viewed-subheading'),
                        maxLines: accessibleText ? null : 1,
                        overflow: accessibleText
                            ? TextOverflow.clip
                            : TextOverflow.ellipsis,
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
                    textStyle: DefaultTextStyle.of(
                      context,
                    ).style.copyWith(fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: cardHeight + 8,
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

  static const titleStyle = TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 10,
    height: 1.05,
    fontWeight: FontWeight.w900,
  );
  static const priceStyle = TextStyle(
    color: BuyV2Colors.navy,
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );
  static const promiseStyle = TextStyle(
    color: BuyV2Colors.green,
    fontSize: 7,
    fontWeight: FontWeight.w800,
  );

  static double minimumHeight(
    BuildContext context,
    BuyV2Session session,
    BuyV2Product product,
    bool accessibleText,
  ) {
    final facts = session.productFactsFor(product);
    final mode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    final width = (accessibleText ? 224.0 : 206.0) - 78 - 17;
    double textHeight(String text, TextStyle style, int? maxLines) =>
        buyV2ValueTextSize(
          context,
          text,
          style,
          maxWidth: width,
          maxLines: maxLines,
        ).height;
    return 17 +
        textHeight(product.title, titleStyle, accessibleText ? null : 2) +
        textHeight(
          product.pack,
          context.buyMeta.copyWith(fontSize: 8),
          accessibleText ? null : 1,
        ) +
        textHeight(buyV2Money(facts.price), priceStyle, null) +
        textHeight(
          '${buyV2CompactFulfilmentModeLabel(mode)} · '
          '${_compactDeliveryPromise(buyV2BuyerDeliveryPromise(facts))}',
          promiseStyle,
          null,
        );
  }

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
                      child: Center(
                        child: AspectRatio(
                          aspectRatio:
                              BuyV2ProductPackshot.resolveMedia(
                                    product,
                                  )?.assetPath ==
                                  BuyV2ProductPackshot.productAtlasPath
                              ? 9 / 8
                              : 1,
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
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 7, 8, 7),
                    child: BuyV2CartAvoidanceRegion(
                      child: Column(
                        key: ValueKey(
                          'buy-recently-viewed-facts-${product.id}',
                        ),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            maxLines: accessibleText ? null : 2,
                            overflow: accessibleText
                                ? TextOverflow.clip
                                : TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.pack,
                            maxLines: accessibleText ? null : 1,
                            overflow: accessibleText
                                ? TextOverflow.clip
                                : TextOverflow.ellipsis,
                            style: context.buyMeta.copyWith(fontSize: 8),
                          ),
                          const Spacer(),
                          Text(buyV2Money(facts.price), style: priceStyle),
                          const SizedBox(height: 1),
                          Text(
                            '${buyV2CompactFulfilmentModeLabel(fulfilmentMode)} · '
                            '${_compactDeliveryPromise(deliveryPromise)}',
                            style: promiseStyle,
                          ),
                        ],
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

class _CatalogueSectionHeader extends StatelessWidget {
  const _CatalogueSectionHeader({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('buy-more-products-heading'),
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 3),
      child: BuyV2CartAvoidanceRegion(
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'More products',
              style: context.buyTitle.copyWith(fontSize: 15),
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
      ),
    );
  }
}

class _FeaturedProductCard extends StatefulWidget {
  const _FeaturedProductCard({required this.session, required this.product});

  final BuyV2Session session;
  final BuyV2Product product;

  static const titleStyle = TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 11,
    height: 1.05,
    fontWeight: FontWeight.w900,
  );

  static double titleExpansion(
    BuildContext context,
    BuyV2Product product,
    double cardWidth,
  ) {
    if (product.destination != BuyV2Destination.medicine) return 0;
    final title = TextSpan(
      text: product.title,
      style: DefaultTextStyle.of(context).style.merge(titleStyle),
    );
    // Match the two card borders and the details' horizontal padding.
    final width = (cardWidth - 18).clamp(1.0, double.infinity);
    final full = TextPainter(
      text: title,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width);
    final capped = TextPainter(
      text: title,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 2,
    )..layout(maxWidth: width);
    // Grow the lane by the newly visible lines, preserving the media/actions.
    final extra = (full.height - capped.height)
        .clamp(0.0, double.infinity)
        .ceilToDouble();
    full.dispose();
    capped.dispose();
    return extra;
  }

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
    final cataloguePromise =
        product.destination == BuyV2Destination.shop &&
            session.shopSaleType == BuyV2ShopSaleType.quickDelivery
        ? 'Nearby'
        : product.destination == BuyV2Destination.shop &&
              session.shopSaleType == BuyV2ShopSaleType.courier
        ? buyerPromise.replaceFirst(RegExp(r'^Delivered\s+'), 'Delivery ')
        : buyerPromise;
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
              '${product.unitPrice}, '
              '${buyV2FulfilmentModeLabel(fulfilmentMode)}, '
              '$cataloguePromise${automaticFulfilment ? ', ${facts.partner}, ${offerDecision!.statusLabel}' : ', fulfilled by ${facts.partner}'}',
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
                            child: BuyV2CartAvoidanceRegion(
                              child: _FeaturedProductAction(
                                session: session,
                                product: product,
                                quantity: quantity,
                                rxBlocked: rxBlocked,
                                offerDecision: offerDecision,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                      child: BuyV2CartAvoidanceRegion(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines:
                                  product.destination ==
                                      BuyV2Destination.medicine
                                  ? null
                                  : 2,
                              overflow: TextOverflow.clip,
                              style: _FeaturedProductCard.titleStyle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.pack,
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: context.buyMeta.copyWith(fontSize: 8),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                Text(
                                  buyV2Money(facts.price),
                                  style: const TextStyle(
                                    color: BuyV2Colors.navy,
                                    fontSize: 14,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  product.unitPrice,
                                  style: context.buyMeta.copyWith(
                                    fontSize: 7.5,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              facts.partner,
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                color: BuyV2Colors.navy,
                                fontSize: 7.5,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _sellerTypeLabel(product.sellerType),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                color: BuyV2Colors.muted,
                                fontSize: 7,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              automaticFulfilment
                                  ? '${buyV2CompactFulfilmentModeLabel(fulfilmentMode)} · ${_compactDeliveryPromise(cataloguePromise)}'
                                  : _compactDeliveryPromise(
                                      facts.deliveryPromise,
                                    ),
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
          if (product.badge.trim().isNotEmpty)
            Positioned(
              key: ValueKey('buy-compact-product-badge-${product.id}'),
              left: 7,
              top: 7,
              right: 50,
              child: Align(
                alignment: Alignment.topLeft,
                child: BuyV2CartAvoidanceRegion(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 92),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: product.requiresPrescription
                          ? BuyV2Colors.navy
                          : BuyV2Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _compactProductBadge(product.badge),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
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
    return Stack(
      children: [
        IgnorePointer(
          ignoring: quantity > 0,
          child: ExcludeSemantics(
            excluding: quantity > 0,
            child: AnimatedSwitcher(
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
                      key: ValueKey(
                        'buy-featured-quantity-shell-${product.id}',
                      ),
                      width: 108,
                      child: _QuantityStepper(
                        key: ValueKey('buy-quantity-${product.id}'),
                        quantity: quantity,
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
                                session.pendingPrescriptionProductId ==
                                    product.id) {
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
            ),
          ),
        ),
        if (quantity > 0)
          Positioned.fill(
            child: _QuantityStepperTargets(
              productId: product.id,
              productTitle: product.title,
              quantity: quantity,
              minimumOrder: product.minimumOrder,
              onEdit: () => showBuyV2QuantityEditor(context, session, product),
              onDecrease: () => session.decrease(product.id),
              onIncrease: () => session.increase(product.id),
            ),
          ),
      ],
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
    this.beforeCartChange,
    this.initialAddQuantity,
    this.beforeSave,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool compact;
  final bool savedContext;
  final ValueChanged<BuyV2Product>? onOpenProduct;
  final bool storeContext;
  final Future<bool> Function(int)? beforeCartChange;
  final int? initialAddQuantity;
  final bool Function()? beforeSave;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildCard);

  Widget _buildCard(BuildContext context, BoxConstraints constraints) {
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
    final cataloguePromise =
        product.destination == BuyV2Destination.shop &&
            session.shopSaleType == BuyV2ShopSaleType.quickDelivery
        ? 'Nearby'
        : product.destination == BuyV2Destination.shop &&
              session.shopSaleType == BuyV2ShopSaleType.courier
        ? buyerPromise.replaceFirst(RegExp(r'^Delivered\s+'), 'Delivery ')
        : buyerPromise;
    final offerDecision = automaticFulfilment
        ? buyV2ResolveProductOfferDecision(product: product, facts: facts)
        : null;
    final requiresOfferReview = offerDecision?.canAdd == false;
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    final stackedQuantity = _gridQuantityStacks(
      constraints.maxWidth - (compact ? 12 : 18),
      buyV2ValueTextSize(context, '$quantity', _gridQuantityStyle).width,
    );
    return BuyV2IntentDepth(
      key: ValueKey('buy-product-depth-${product.id}'),
      spatial: true,
      child: Semantics(
        label:
            '${product.title}, ${product.pack}, ${buyV2Money(facts.price)}, '
            '${product.unitPrice}, '
            '${buyV2FulfilmentModeLabel(fulfilmentMode)}, '
            '$cataloguePromise${automaticFulfilment ? ', ${facts.partner}, ${offerDecision!.statusLabel}' : ', fulfilled by ${facts.partner}'}',
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
                    if (compact)
                      Expanded(
                        child: _ProductVisual(
                          product: product,
                          compact: true,
                          reservedActionWidth: savedContext ? 68 : 42,
                        ),
                      )
                    else
                      _ProductVisual(
                        product: product,
                        compact: false,
                        reservedActionWidth: savedContext ? 68 : 42,
                      ),
                    Flexible(
                      flex: compact ? 0 : 1,
                      fit: compact ? FlexFit.loose : FlexFit.tight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 6 : 9,
                          compact ? 4 : 7,
                          compact ? 6 : 9,
                          compact ? 2 : 8,
                        ),
                        child: BuyV2CartAvoidanceRegion(
                          child: Column(
                            mainAxisSize: compact
                                ? MainAxisSize.min
                                : MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!compact &&
                                  product.brand.trim().isNotEmpty) ...[
                                Text(
                                  product.brand,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.buyEyebrow.copyWith(
                                    fontSize: 7,
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                              Text(
                                product.title,
                                maxLines:
                                    compact &&
                                        product.destination ==
                                            BuyV2Destination.medicine
                                    ? null
                                    : compact
                                    ? 3
                                    : 2,
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
                              Wrap(
                                spacing: 3,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  Text(
                                    buyV2Money(facts.price),
                                    style: TextStyle(
                                      color: BuyV2Colors.navy,
                                      fontSize: compact ? 14 : 18,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (compact) ...[
                                    Text(
                                      product.unitPrice,
                                      style: context.buyMeta.copyWith(
                                        fontSize: 7.2,
                                        height: 1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
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
                                                      ? offerDecision!
                                                            .statusLabel
                                                      : automaticFulfilment
                                                      ? '${buyV2CompactFulfilmentModeLabel(fulfilmentMode)} · '
                                                            '${_compactDeliveryPromise(cataloguePromise)}'
                                                      : '${facts.partner} · '
                                                            '${_compactDeliveryPromise(facts.deliveryPromise)}'
                                                : cataloguePromise,
                                            maxLines: null,
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
                              if (!compact) const SizedBox(height: 6),
                              IgnorePointer(
                                ignoring: quantity > 0,
                                child: ExcludeSemantics(
                                  excluding: quantity > 0,
                                  child: AnimatedSwitcher(
                                    key: ValueKey(
                                      'buy-product-action-motion-${product.id}',
                                    ),
                                    duration: BuyV2Motion.resolved(
                                      context,
                                      BuyV2Motion.stateChange,
                                    ),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, animation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: .97,
                                              end: 1,
                                            ).animate(animation),
                                            child: child,
                                          ),
                                        ),
                                    child: quantity > 0
                                        ? _QuantityStepper(
                                            key: ValueKey(
                                              'buy-quantity-${product.id}',
                                            ),
                                            quantity: quantity,
                                            stacked: stackedQuantity,
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
                                                  onTap: () async {
                                                    HapticFeedback.selectionClick();
                                                    if (requiresOfferReview) {
                                                      openProduct();
                                                      return;
                                                    }
                                                    final count =
                                                        initialAddQuantity ??
                                                        product.minimumOrder;
                                                    if (await beforeCartChange
                                                            ?.call(count) ==
                                                        false) {
                                                      return;
                                                    }
                                                    final added = session
                                                        .addProduct(
                                                          product.id,
                                                          quantity: count,
                                                        );
                                                    if (!added &&
                                                        context.mounted &&
                                                        session.pendingPrescriptionProductId ==
                                                            product.id) {
                                                      showBuyV2PrescriptionSheet(
                                                        context,
                                                        session,
                                                      );
                                                    }
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(11),
                                                  child: Center(
                                                    child: Container(
                                                      height: 32,
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            requiresOfferReview
                                                            ? BuyV2Colors
                                                                  .softOrange
                                                            : rxBlocked
                                                            ? BuyV2Colors.navy
                                                            : Colors.white,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              requiresOfferReview
                                                              ? BuyV2Colors
                                                                    .orange
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
                                                              color: BuyV2Colors
                                                                  .orange,
                                                              size: 20,
                                                            )
                                                          : rxBlocked
                                                          ? const Text(
                                                              'Use Rx',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 9,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                              ),
                                                            )
                                                          : const Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .add_rounded,
                                                                  color:
                                                                      BuyV2Colors
                                                                          .navy,
                                                                  size: 17,
                                                                ),
                                                                SizedBox(
                                                                  width: 3,
                                                                ),
                                                                Text(
                                                                  'Add',
                                                                  style: TextStyle(
                                                                    color:
                                                                        BuyV2Colors
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
                                ),
                              ),
                            ],
                          ),
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
                    beforeToggle: beforeSave,
                  ),
                ),
                if (quantity > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: compact ? 2 : 8,
                    height:
                        BuyV2Metrics.minimumTap +
                        (stackedQuantity
                            ? _gridQuantityLabelHeight(
                                MediaQuery.textScalerOf(context).scale(1),
                              )
                            : 0),
                    child: _QuantityStepperTargets(
                      stacked: stackedQuantity,
                      visualInset: compact ? 6 : 9,
                      productId: product.id,
                      productTitle: product.title,
                      quantity: quantity,
                      minimumOrder: product.minimumOrder,
                      onEdit: () => showBuyV2QuantityEditor(
                        context,
                        session,
                        product,
                        beforeSave: beforeCartChange,
                      ),
                      onDecrease: () async {
                        final next = quantity <= product.minimumOrder
                            ? 0
                            : quantity - 1;
                        if (await beforeCartChange?.call(next) != false) {
                          session.decrease(product.id);
                        }
                      },
                      onIncrease: () async {
                        if (beforeCartChange == null) {
                          session.increase(product.id);
                        } else if (await beforeCartChange!(quantity + 1)) {
                          session.setCartQuantity(
                            product.id,
                            '${quantity + 1}',
                          );
                        }
                      },
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

String _sellerTypeLabel(String source) => _publicProviderType(source);

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    super.key,
    required this.quantity,
    this.stacked = true,
  });

  final int quantity;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final labelHeight = _gridQuantityLabelHeight(
      MediaQuery.textScalerOf(context).scale(1),
    );
    final value = LayoutBuilder(
      builder: (context, constraints) => BuyV2FiniteValueTransition(
        key: const ValueKey('buy-grid-quantity-value-motion'),
        incomingOnly: true,
        stateKey: quantity,
        text: '$quantity',
        maxLines: null,
        ownerSize: Size(constraints.maxWidth, stacked ? labelHeight - 2 : 42),
        style: _gridQuantityStyle,
      ),
    );
    return ExcludeSemantics(
      child: Container(
        height: BuyV2Metrics.minimumTap + (stacked ? labelHeight : 0),
        decoration: BoxDecoration(
          color: BuyV2Colors.softBlue,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0x23000080)),
        ),
        child: stacked
            ? Column(
                children: [
                  SizedBox(height: labelHeight - 2, child: value),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Icon(
                              Icons.remove,
                              size: 17,
                              color: BuyV2Colors.navy,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Icon(
                              Icons.add,
                              size: 17,
                              color: BuyV2Colors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(
                    width: 44,
                    child: Icon(
                      Icons.remove,
                      size: 17,
                      color: BuyV2Colors.navy,
                    ),
                  ),
                  Expanded(child: value),
                  const SizedBox(
                    width: 44,
                    child: Icon(Icons.add, size: 17, color: BuyV2Colors.navy),
                  ),
                ],
              ),
      ),
    );
  }
}

class _QuantityStepperTargets extends StatelessWidget {
  const _QuantityStepperTargets({
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.minimumOrder,
    required this.onEdit,
    required this.onDecrease,
    required this.onIncrease,
    this.visualInset = 0,
    this.stacked = true,
  });

  final String productId;
  final String productTitle;
  final int quantity;
  final int minimumOrder;
  final VoidCallback onEdit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final double visualInset;
  final bool stacked;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const target = BuyV2Metrics.minimumTap;
      final maximumInset = ((constraints.maxWidth - target * 2) / 2).clamp(
        0.0,
        double.infinity,
      );
      final inset = stacked
          ? (visualInset +
                    1 +
                    (constraints.maxWidth - visualInset * 2 - 2) / 4 -
                    target / 2)
                .clamp(0.0, maximumInset)
                .toDouble()
          : visualInset;
      Widget action(String verb, String tooltip, VoidCallback onTap) =>
          Semantics(
            label: '$verb $productTitle quantity from $quantity',
            button: true,
            excludeSemantics: true,
            onTap: onTap,
            child: IconButton(
              tooltip: tooltip,
              onPressed: onTap,
              constraints: const BoxConstraints.tightFor(
                width: target,
                height: target,
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.standard,
              icon: const SizedBox.shrink(),
            ),
          );
      return Stack(
        children: [
          Positioned(
            left: stacked ? 0 : visualInset + target,
            right: stacked ? 0 : visualInset + target,
            top: 0,
            height: stacked
                ? _gridQuantityLabelHeight(
                    MediaQuery.textScalerOf(context).scale(1),
                  )
                : target,
            child: Semantics(
              label:
                  'Edit quantity of $productTitle, $quantity ${quantity == 1 ? 'pack' : 'packs'} in Cart',
              button: true,
              excludeSemantics: true,
              onTap: onEdit,
              child: TextButton(
                key: ValueKey('buy-grid-edit-quantity-$productId'),
                onPressed: onEdit,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            left: inset,
            bottom: 0,
            width: target,
            height: target,
            child: action(
              'Decrease',
              quantity <= minimumOrder ? 'Remove from Cart' : 'Remove one',
              onDecrease,
            ),
          ),
          Positioned(
            right: inset,
            bottom: 0,
            width: target,
            height: target,
            child: action('Increase', 'Add one', onIncrease),
          ),
        ],
      );
    },
  );
}

class _ProductSaveButton extends StatelessWidget {
  const _ProductSaveButton({
    required this.session,
    required this.product,
    this.showRemoveLabel = false,
    this.beforeToggle,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool showRemoveLabel;
  final bool Function()? beforeToggle;

  @override
  Widget build(BuildContext context) =>
      BuyV2CartAvoidanceRegion(child: _buildAction(context));

  Widget _buildAction(BuildContext context) {
    final saved = session.isSaved(product.id);
    void toggleSaved() {
      if (beforeToggle?.call() == false) return;
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
          if (product.badge.trim().isNotEmpty)
            Positioned(
              key: ValueKey('buy-product-card-badge-${product.id}'),
              left: 6,
              top: 6,
              right: compact ? reservedActionWidth : 6,
              child: Align(
                alignment: Alignment.topLeft,
                child: BuyV2CartAvoidanceRegion(
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
                      compact
                          ? _compactProductBadge(product.badge)
                          : product.badge,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 8 : 8,
                        fontWeight: FontWeight.w900,
                      ),
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
