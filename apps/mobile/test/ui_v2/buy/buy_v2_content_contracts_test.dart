import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';

class _MutableFactsAdapter implements BuyV2ProductFactsAdapter {
  _MutableFactsAdapter(this.snapshot);

  BuyV2ProductFactsSnapshot snapshot;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) => snapshot;
}

class _SponsoredFixtureAdapter implements BuyV2SponsoredContentAdapter {
  const _SponsoredFixtureAdapter();

  @override
  BuyV2SponsoredContent? contentFor(BuyV2SponsoredPlacement placement) {
    return BuyV2SponsoredContent(
      id: 'fixture-${placement.name}',
      placement: placement,
      format: BuyV2SponsoredFormat.card,
      disclosure: 'Sponsored',
      title: 'Contract fixture',
      detail: 'This fixture must never reach a production surface.',
    );
  }
}

void main() {
  group('Buy V2 content boundaries', () {
    test('default product facts remain truthful catalogue facts', () {
      final session = BuyV2Session(core: BuySession());
      final product = BuyV2Catalogue.products.first;
      final facts = session.productFactsFor(product);

      expect(facts.productId, product.id);
      expect(facts.price, product.price);
      expect(facts.deliveryPromise, product.deliveryPromise);
      expect(facts.partner, product.seller);
      expect(facts.sourceId, 'approved-buy-catalogue');
      expect(facts.fulfilmentMode, BuyV2FulfilmentMode.quickLocal);
      expect(facts.isLive, isFalse);
      expect(facts.stale, isFalse);

      final content = session.productContentFor(product);
      expect(content.state, BuyV2ProductContentState.ready);
      expect(content.sourceId, 'approved-buy-catalogue');
      expect(content.media, hasLength(1));
      expect(content.highlights, isNotEmpty);
      expect(content.specifications, isNotEmpty);
      expect(content.description, isNotEmpty);

      final trust = session.marketplaceTrustFor(product);
      expect(trust.state, BuyV2MarketplaceTrustState.ready);
      expect(trust.sourceId, 'approved-buy-catalogue');
      expect(trust.partnerName, product.seller);
      expect(trust.partnerType, product.partnerRole);
      expect(trust.productRating, isNull);
    });

    test('catalogue fulfilment modes remain contextual and explicit', () {
      final shopQuick = BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.shop &&
            product.deliveryPromise.contains('min'),
      );
      final shopScheduled = BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.shop &&
            !product.deliveryPromise.contains('min'),
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (product) => product.destination == BuyV2Destination.wholesale,
      );

      expect(
        buyV2CatalogueFulfilmentModeFor(shopQuick),
        BuyV2FulfilmentMode.quickLocal,
      );
      expect(
        buyV2CatalogueFulfilmentModeFor(shopScheduled),
        BuyV2FulfilmentMode.standardCourier,
      );
      expect(
        buyV2CatalogueFulfilmentModeFor(wholesale),
        BuyV2FulfilmentMode.bulkFreight,
      );
    });

    test('replaceable product facts require source and observed time', () {
      final product = BuyV2Catalogue.products.first;
      final adapter = _MutableFactsAdapter(
        BuyV2ProductFactsSnapshot(
          productId: product.id,
          price: product.price,
          deliveryPromise: product.deliveryPromise,
          partner: product.seller,
          orderabilityLabel: 'Available to add',
          sourceId: 'catalogue-test-adapter',
        ),
      );
      final session = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: adapter,
      );
      expect(session.productFactsFor(product).isLive, isFalse);

      final observedAt = DateTime.utc(2026, 7, 31, 6, 45);
      adapter.snapshot = adapter.snapshot.copyWith(
        price: product.price + 2,
        deliveryPromise: 'Updated delivery commitment',
        observedAt: observedAt,
        sourceId: 'catalogue-test-adapter',
      );

      expect(session.refreshProductFacts(product.id), isTrue);
      final refreshed = session.productFactsFor(product);
      expect(refreshed.price, product.price + 2);
      expect(refreshed.observedAt, observedAt);
      expect(refreshed.sourceId, 'catalogue-test-adapter');
      expect(refreshed.isLive, isTrue);
    });

    test('invalid product facts fail closed without replacing the product', () {
      final product = BuyV2Catalogue.products.first;
      final adapter = _MutableFactsAdapter(
        BuyV2ProductFactsSnapshot(
          productId: 'another-product',
          price: product.price,
          deliveryPromise: product.deliveryPromise,
          partner: product.seller,
          orderabilityLabel: 'Available to add',
          sourceId: 'invalid-test-adapter',
        ),
      );
      final session = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: adapter,
      );

      final initial = session.productFactsFor(product);
      expect(initial.productId, product.id);
      expect(initial.price, product.price);
      expect(initial.sourceId, 'approved-buy-catalogue');
      expect(session.refreshProductFacts(product.id), isFalse);
      expect(session.notice, 'Product information could not be refreshed.');
      expect(session.product(product.id), same(product));
    });

    test('sponsored and video surfaces are disabled by default', () {
      const adapter = BuyV2DisabledSponsoredContentAdapter();
      for (final placement in BuyV2SponsoredPlacement.values) {
        expect(adapter.contentFor(placement), isNull);
      }

      expect(BuyV2ExperienceBudgets.maximumSponsoredCardsPerCatalogue, 1);
      expect(BuyV2ExperienceBudgets.maximumInlineVideosPerViewport, 1);
      expect(BuyV2ExperienceBudgets.maximumPreloadedInlineVideos, 0);
      expect(BuyV2ExperienceBudgets.autoplayAudioAllowed, isFalse);
      expect(BuyV2ExperienceBudgets.perpetualDecorativeMotionAllowed, isFalse);
    });

    test('unapproved sponsored adapters stay fail closed', () {
      final session = BuyV2Session(
        core: BuySession(),
        sponsoredContentAdapter: const _SponsoredFixtureAdapter(),
      );

      expect(BuyV2Session.sponsoredContentActivationApproved, isFalse);
      for (final placement in BuyV2SponsoredPlacement.values) {
        expect(session.sponsoredContentFor(placement), isNull);
      }
    });

    test('inline video contract requires poster, captions and transcript', () {
      expect(
        () => BuyV2SponsoredContent(
          id: 'video-contract-test',
          placement: BuyV2SponsoredPlacement.catalogueAfterDiscovery,
          format: BuyV2SponsoredFormat.inlineVideo,
          disclosure: 'Sponsored',
          title: 'Contract test',
          detail: 'No production content',
        ),
        throwsAssertionError,
      );
    });
  });
}
