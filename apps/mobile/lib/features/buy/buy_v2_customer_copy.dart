import 'buy_v2_models.dart';

String buyV2CustomerStoreName(String name, String? storeId) {
  final match = RegExp(
    r'^buy-catalogue-dev-v1-(shop|wholesale|medicine)-store-([0-9]{6})$',
  ).firstMatch(storeId ?? '');
  if (match == null || name != 'Mool Market ${match.group(2)}') return name;
  final number = int.parse(match.group(2)!);
  if (number < 1 || number > 100000) return name;
  return 'Mool Market $number';
}

/// Presentation only: development catalogue bookkeeping is not a product name.
/// Require the complete generated identity and matching decoration so genuine
/// model numbers, pack sizes and all non-fixture supplier content stay intact.
extension BuyV2CustomerProductCopy on BuyV2Product {
  String customerSeller(String name) => buyV2CustomerStoreName(name, storeId);

  /// Compact SKU identity where a full variant row is not otherwise shown.
  String get customerVariantPack {
    if (!hasStructuredVariants) return pack;
    final seen = <String>{};
    return [
      ...variantAttributes.map((attribute) => attribute.optionLabel),
      pack,
    ].where((value) => seen.add(value.trim().toLowerCase())).join(' · ');
  }

  String? get _developmentSku {
    final match = RegExp(
      r'^buy-catalogue-dev-v1-(shop|wholesale|medicine)-store-([0-9]{6})-sku-([0-9]{4})$',
    ).firstMatch(id);
    if (match == null || match.group(1) != destination.name) return null;
    final sku = int.parse(match.group(3)!);
    if (sku < 1 ||
        sku > 5000 ||
        storeId !=
            'buy-catalogue-dev-v1-${destination.name}-store-${match.group(2)}' ||
        canonicalId !=
            'buy-catalogue-dev-v1-${destination.name}-product-$sku') {
      return null;
    }
    return '$sku';
  }

  String get customerTitle {
    final sku = _developmentSku;
    final suffix = ' $sku';
    return sku != null && title.endsWith(suffix)
        ? title.substring(0, title.length - suffix.length)
        : title;
  }

  /// Normalize only complete, known generated field values, never substrings
  /// inside supplier prose or genuine model numbers.
  String customerContent(String value) {
    if (_developmentSku == null) return value;
    if (value == title) return customerTitle;
    if (value == variant) return customerVariant;
    final generatedDescription = '$title \u00b7 $variant. $pack at $unitPrice.';
    if (value == generatedDescription) {
      return '$customerTitle \u00b7 $customerVariant. $pack at $unitPrice.';
    }
    return customerSeller(value);
  }

  String get customerVariant {
    final sku = _developmentSku;
    final suffix = ' · SKU $sku';
    return sku != null && variant.endsWith(suffix)
        ? variant.substring(0, variant.length - suffix.length)
        : variant;
  }
}

/// Present a fulfilment partner using its exact line identity, never name-only
/// matching. Mixed-store groups are left unchanged.
extension BuyV2CustomerGroupCopy on BuyV2FulfilmentGroup {
  String get customerPartner {
    final ids = lines.map((line) => line.product.storeId).toSet();
    return ids.length == 1
        ? buyV2CustomerStoreName(partner, ids.single)
        : partner;
  }
}

extension BuyV2CustomerOrderCopy on BuyV2Order {
  String get customerPartner {
    // Retained orders may predate line snapshots. Recover only a complete,
    // matching generated Store identity from every persisted SKU identifier.
    // Never normalize real supplier names from their spelling alone.
    final ids = lines.isNotEmpty
        ? lines.map((line) => line.product.storeId).toSet()
        : productIds
              .map(
                (id) => RegExp(
                  r'^(buy-catalogue-dev-v1-(?:shop|wholesale|medicine)-store-[0-9]{6})-sku-[0-9]{4}$',
                ).firstMatch(id)?.group(1),
              )
              .toSet();
    return ids.length == 1
        ? buyV2CustomerStoreName(partner, ids.single)
        : partner;
  }
}
