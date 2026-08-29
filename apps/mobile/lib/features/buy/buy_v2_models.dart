import 'buy_v2_catalogue_data.dart';

enum BuyV2Destination { shop, wholesale, medicine, orders }

/// Presentation-only direction for a genuine Buy surface replacement.
///
/// Route, Back and restoration outcomes remain owned by [BuyV2Session]. This
/// value lets the fixed Buy body communicate that already-decided outcome; it
/// must never be used to choose, delay or persist navigation.
enum BuyV2NavigationMotionDirection { forward, back, replace }

enum BuyV2View {
  catalogue,
  product,
  cart,
  checkout,
  confirmation,
  tracking,
  orderItems,
  assist,
  account,
  recovery,
}

enum BuyV2CartScope { all, shop, wholesale, medicine }

enum BuyV2AddressKind { home, work, thirdParty, other }

enum BuyV2OrderStatus { preparing, confirmed, dispatched, arriving, delivered }

enum BuyV2OrdersTab { active, delivered }

enum BuyV2RecoveryKind {
  priceUpdate,
  stockUnavailable,
  serviceAreaUnavailable,
  paymentFailed,
  networkInterruption,
  deliveryDelay,
}

class BuyV2Category {
  const BuyV2Category({
    required this.id,
    required this.label,
    required this.glyph,
  });

  final String id;
  final String label;
  final String glyph;
}

class BuyV2Product {
  const BuyV2Product({
    required this.id,
    String? canonicalId,
    required this.destination,
    required this.categoryId,
    required this.brand,
    required this.title,
    required this.variant,
    required this.pack,
    required this.price,
    required this.unitPrice,
    required this.badge,
    required this.seller,
    required this.sellerType,
    required this.deliveryPromise,
    required this.origin,
    required this.confirmedOn,
    required this.visualLabel,
    required this.visualKind,
    this.mrp,
    this.requiresPrescription = false,
    this.composition,
    this.regulatoryNote,
    this.minimumOrder = 1,
    this.returnPolicy,
    this.freightIncluded = false,
    this.manufacturerVerified = false,
  }) : canonicalId = canonicalId ?? id;

  final String id;
  final String canonicalId;
  final BuyV2Destination destination;
  final String categoryId;
  final String brand;
  final String title;
  final String variant;
  final String pack;
  final int price;
  final String unitPrice;
  final String badge;
  final String seller;
  final String sellerType;
  final String deliveryPromise;
  final String origin;
  final String confirmedOn;
  final String visualLabel;
  final String visualKind;
  final int? mrp;
  final bool requiresPrescription;
  final String? composition;
  final String? regulatoryNote;
  final int minimumOrder;
  final String? returnPolicy;
  final bool freightIncluded;
  final bool manufacturerVerified;

  BuyV2Product copyWith({
    int? price,
    String? deliveryPromise,
    String? seller,
    String? sellerType,
    String? confirmedOn,
  }) => BuyV2Product(
    id: id,
    canonicalId: canonicalId,
    destination: destination,
    categoryId: categoryId,
    brand: brand,
    title: title,
    variant: variant,
    pack: pack,
    price: price ?? this.price,
    unitPrice: unitPrice,
    badge: badge,
    seller: seller ?? this.seller,
    sellerType: sellerType ?? this.sellerType,
    deliveryPromise: deliveryPromise ?? this.deliveryPromise,
    origin: origin,
    confirmedOn: confirmedOn ?? this.confirmedOn,
    visualLabel: visualLabel,
    visualKind: visualKind,
    mrp: mrp,
    requiresPrescription: requiresPrescription,
    composition: composition,
    regulatoryNote: regulatoryNote,
    minimumOrder: minimumOrder,
    returnPolicy: returnPolicy,
    freightIncluded: freightIncluded,
    manufacturerVerified: manufacturerVerified,
  );

  String get partnerRole => buyV2PartnerRoleFor(destination, sellerType);

  String? get regulatoryTrustFact =>
      destination == BuyV2Destination.medicine ? 'Licensed pharmacy' : null;
}

String buyV2PartnerRoleFor(BuyV2Destination destination, String sourceRole) {
  final normalized = sourceRole.toLowerCase();
  if (normalized.contains('manufacturer')) {
    return 'Mool Manufacturer Partner';
  }
  return switch (destination) {
    BuyV2Destination.shop => 'Mool Retail Partner',
    BuyV2Destination.wholesale => 'Mool Trade Partner',
    BuyV2Destination.medicine => 'Mool Pharmacy Partner',
    BuyV2Destination.orders => 'Mool Fulfilment Partner',
  };
}

class BuyV2CustomerReview {
  const BuyV2CustomerReview({
    required this.productCanonicalId,
    required this.rating,
    required this.comment,
    required this.updatedLabel,
  });

  final String productCanonicalId;
  final int rating;
  final String comment;
  final String updatedLabel;
}

class BuyV2CartLine {
  const BuyV2CartLine({required this.product, required this.quantity});

  final BuyV2Product product;
  final int quantity;

  int get total => product.price * quantity;

  BuyV2CartLine copyWith({BuyV2Product? product, int? quantity}) =>
      BuyV2CartLine(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );
}

class BuyV2FulfilmentGroup {
  const BuyV2FulfilmentGroup({
    required this.destination,
    required this.partner,
    required this.partnerType,
    required this.promise,
    required this.lines,
    this.promisedByLabel,
  });

  final BuyV2Destination destination;
  final String partner;
  final String partnerType;
  final String promise;
  final List<BuyV2CartLine> lines;
  final String? promisedByLabel;

  int get itemCount => lines.fold(0, (total, line) => total + line.quantity);

  int get total => lines.fold(0, (total, line) => total + line.total);

  String get key => '${destination.name}|$partner';

  List<String> get productIds =>
      lines.map((line) => line.product.id).toList(growable: false);
}

class BuyV2Address {
  const BuyV2Address({
    required this.id,
    required this.kind,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.line,
    required this.area,
    required this.pinCode,
    required this.landmark,
  });

  final String id;
  final BuyV2AddressKind kind;
  final String label;
  final String recipient;
  final String phone;
  final String line;
  final String area;
  final String pinCode;
  final String landmark;

  String get shortLine => '$area · $pinCode';

  String get compactLine => '${area.split(',').first.trim()} · $pinCode';
}

class BuyV2Order {
  const BuyV2Order({
    required this.id,
    required this.destination,
    required this.title,
    required this.itemSummary,
    required this.total,
    required this.partner,
    required this.partnerType,
    required this.promise,
    required this.destinationLabel,
    required this.progress,
    required this.status,
    this.purchaseId,
    this.promisedByLabel,
    this.updatedDeliveryEstimate,
    this.productIds = const [],
    this.lines = const [],
    this.paymentMethod,
    this.recipient,
    this.addressLine,
    this.deliveryInstruction,
    this.tip = 0,
  });

  final String id;
  final BuyV2Destination destination;
  final String title;
  final String itemSummary;
  final int total;
  final String partner;
  final String partnerType;
  final String promise;
  final String destinationLabel;
  final double progress;
  final BuyV2OrderStatus status;
  final String? purchaseId;
  final String? promisedByLabel;
  final String? updatedDeliveryEstimate;
  final List<String> productIds;
  final List<BuyV2CartLine> lines;
  final String? paymentMethod;
  final String? recipient;
  final String? addressLine;
  final String? deliveryInstruction;
  final int tip;
}

class _BuyV2CommerceSeed {
  const _BuyV2CommerceSeed({
    required this.id,
    required this.title,
    required this.brand,
    required this.shopCategory,
    required this.wholesaleCategory,
    required this.variant,
    required this.shopPack,
    required this.shopPrice,
    required this.shopUnit,
    required this.shopBadge,
    required this.shopSeller,
    required this.shopSellerType,
    required this.shopDelivery,
    required this.shopReturnPolicy,
    required this.wholesalePack,
    required this.wholesalePrice,
    required this.wholesaleUnit,
    required this.wholesaleBadge,
    required this.wholesaleSeller,
    required this.wholesaleSellerType,
    required this.wholesaleDelivery,
    required this.wholesaleReturnPolicy,
  });

  factory _BuyV2CommerceSeed.fromRow(String row) {
    final values = row.split('|');
    if (values.length != 22) {
      throw FormatException(
        'Buy V2 commerce seed ${values.firstOrNull ?? '<empty>'} '
        'has ${values.length} fields; expected 22.',
      );
    }
    return _BuyV2CommerceSeed(
      id: values[0],
      title: values[1],
      brand: values[2],
      shopCategory: values[3],
      wholesaleCategory: values[4],
      variant: values[5],
      shopPack: values[6],
      shopPrice: int.parse(values[7]),
      shopUnit: values[8],
      shopBadge: values[9],
      shopSeller: values[10],
      shopSellerType: values[11],
      shopDelivery: values[12],
      shopReturnPolicy: values[13],
      wholesalePack: values[14],
      wholesalePrice: int.parse(values[15]),
      wholesaleUnit: values[16],
      wholesaleBadge: values[17],
      wholesaleSeller: values[18],
      wholesaleSellerType: values[19],
      wholesaleDelivery: values[20],
      wholesaleReturnPolicy: values[21],
    );
  }

  final String id;
  final String title;
  final String brand;
  final String shopCategory;
  final String wholesaleCategory;
  final String variant;
  final String shopPack;
  final int shopPrice;
  final String shopUnit;
  final String shopBadge;
  final String shopSeller;
  final String shopSellerType;
  final String shopDelivery;
  final String shopReturnPolicy;
  final String wholesalePack;
  final int wholesalePrice;
  final String wholesaleUnit;
  final String wholesaleBadge;
  final String wholesaleSeller;
  final String wholesaleSellerType;
  final String wholesaleDelivery;
  final String wholesaleReturnPolicy;
}

abstract final class BuyV2Catalogue {
  static const shopCategories = <BuyV2Category>[
    BuyV2Category(id: 'all', label: 'For you', glyph: '✦'),
    BuyV2Category(
      id: 'fruits-vegetables',
      label: 'Fruits & vegetables',
      glyph: '●',
    ),
    BuyV2Category(id: 'dairy-bakery', label: 'Dairy & bakery', glyph: '◒'),
    BuyV2Category(id: 'eggs-poultry', label: 'Eggs & poultry', glyph: '◉'),
    BuyV2Category(id: 'meat-seafood', label: 'Meat & seafood', glyph: '◍'),
    BuyV2Category(
      id: 'flour-rice-grains',
      label: 'Flour, rice & grains',
      glyph: '◇',
    ),
    BuyV2Category(id: 'dals-staples', label: 'Dals & staples', glyph: '◆'),
    BuyV2Category(id: 'oils-ghee', label: 'Oil & ghee', glyph: '◐'),
    BuyV2Category(id: 'ground-spices', label: 'Ground spices', glyph: '✧'),
    BuyV2Category(id: 'whole-spices', label: 'Whole spices', glyph: '✣'),
    BuyV2Category(
      id: 'breakfast-cereals',
      label: 'Breakfast & cereals',
      glyph: '☀',
    ),
    BuyV2Category(id: 'instant-foods', label: 'Instant foods', glyph: '▣'),
    BuyV2Category(id: 'sauces-spreads', label: 'Sauces & spreads', glyph: '◈'),
    BuyV2Category(
      id: 'biscuits-chocolate',
      label: 'Biscuits & chocolate',
      glyph: '○',
    ),
    BuyV2Category(id: 'namkeen-chips', label: 'Namkeen & chips', glyph: '◌'),
    BuyV2Category(id: 'tea-coffee', label: 'Tea & coffee', glyph: '◫'),
    BuyV2Category(id: 'juices-water', label: 'Juices & water', glyph: '◧'),
    BuyV2Category(id: 'frozen-foods', label: 'Frozen foods', glyph: '❄'),
    BuyV2Category(
      id: 'icecream-cheese',
      label: 'Ice cream & cheese',
      glyph: '◓',
    ),
    BuyV2Category(id: 'bath-hand-care', label: 'Bath & hand care', glyph: '✚'),
    BuyV2Category(id: 'oral-care', label: 'Oral care', glyph: '⌁'),
    BuyV2Category(id: 'hair-care', label: 'Hair care', glyph: '♢'),
    BuyV2Category(id: 'skin-care', label: 'Skin care', glyph: '◊'),
    BuyV2Category(
      id: 'surface-cleaners',
      label: 'Surface cleaners',
      glyph: '⌂',
    ),
    BuyV2Category(id: 'air-waste-care', label: 'Air & waste care', glyph: '◎'),
    BuyV2Category(
      id: 'laundry-dishwash',
      label: 'Laundry & dishwash',
      glyph: '≋',
    ),
    BuyV2Category(id: 'diapers-wipes', label: 'Diapers & wipes', glyph: '◉'),
    BuyV2Category(id: 'baby-care', label: 'Baby care', glyph: '◎'),
    BuyV2Category(
      id: 'health-wellness',
      label: 'Health & wellness',
      glyph: '＋',
    ),
    BuyV2Category(id: 'dog-care', label: 'Dog care', glyph: '♡'),
    BuyV2Category(id: 'cat-care', label: 'Cat care', glyph: '♧'),
    BuyV2Category(
      id: 'food-storage-packs',
      label: 'Food storage & packs',
      glyph: '▤',
    ),
    BuyV2Category(id: 'cups-tissues', label: 'Cups & tissues', glyph: '◒'),
    BuyV2Category(id: 'school-office', label: 'School & office', glyph: '□'),
    BuyV2Category(id: 'shop-supplies', label: 'Shop supplies', glyph: '▦'),
  ];

  static const wholesaleCategories = <BuyV2Category>[
    BuyV2Category(id: 'all', label: 'Best prices', glyph: '✦'),
    BuyV2Category(id: 'retail-supplies', label: 'Retail supplies', glyph: '▦'),
    BuyV2Category(
      id: 'horeca-food-packs',
      label: 'HoReCa food packs',
      glyph: '▤',
    ),
    BuyV2Category(
      id: 'horeca-tableware',
      label: 'HoReCa tableware',
      glyph: '◒',
    ),
    BuyV2Category(
      id: 'stationery-office',
      label: 'Stationery & office',
      glyph: '□',
    ),
    BuyV2Category(
      id: 'fruits-vegetables',
      label: 'Fruits & vegetables',
      glyph: '●',
    ),
    BuyV2Category(id: 'dairy-bakery', label: 'Dairy & bakery', glyph: '◒'),
    BuyV2Category(id: 'eggs-poultry', label: 'Eggs & poultry', glyph: '◉'),
    BuyV2Category(id: 'meat-seafood', label: 'Meat & seafood', glyph: '◍'),
    BuyV2Category(
      id: 'flour-rice-grains',
      label: 'Flour, rice & grains',
      glyph: '◇',
    ),
    BuyV2Category(id: 'dals-staples', label: 'Dals & staples', glyph: '◆'),
    BuyV2Category(id: 'oils-ghee', label: 'Oils & ghee', glyph: '◐'),
    BuyV2Category(id: 'ground-spices', label: 'Ground spices', glyph: '✧'),
    BuyV2Category(id: 'whole-spices', label: 'Whole spices', glyph: '✣'),
    BuyV2Category(
      id: 'breakfast-cereals',
      label: 'Breakfast & cereals',
      glyph: '☀',
    ),
    BuyV2Category(id: 'instant-foods', label: 'Instant foods', glyph: '▣'),
    BuyV2Category(id: 'sauces-spreads', label: 'Sauces & spreads', glyph: '◈'),
    BuyV2Category(
      id: 'biscuits-chocolate',
      label: 'Biscuits & chocolate',
      glyph: '○',
    ),
    BuyV2Category(id: 'namkeen-chips', label: 'Namkeen & chips', glyph: '◌'),
    BuyV2Category(id: 'tea-coffee', label: 'Tea & coffee', glyph: '◫'),
    BuyV2Category(id: 'juices-water', label: 'Juices & water', glyph: '◧'),
    BuyV2Category(id: 'frozen-foods', label: 'Frozen foods', glyph: '❄'),
    BuyV2Category(
      id: 'icecream-cheese',
      label: 'Ice cream & cheese',
      glyph: '◓',
    ),
    BuyV2Category(id: 'bath-hand-care', label: 'Bath & hand care', glyph: '✚'),
    BuyV2Category(id: 'oral-care', label: 'Oral care', glyph: '⌁'),
    BuyV2Category(id: 'hair-care', label: 'Hair care', glyph: '♢'),
    BuyV2Category(id: 'skin-care', label: 'Skin care', glyph: '◊'),
    BuyV2Category(
      id: 'surface-cleaners',
      label: 'Surface cleaners',
      glyph: '⌂',
    ),
    BuyV2Category(id: 'air-waste-care', label: 'Air & waste care', glyph: '◎'),
    BuyV2Category(
      id: 'laundry-dishwash',
      label: 'Laundry & dishwash',
      glyph: '≋',
    ),
    BuyV2Category(id: 'diapers-wipes', label: 'Diapers & wipes', glyph: '◉'),
    BuyV2Category(id: 'baby-care', label: 'Baby care', glyph: '◎'),
    BuyV2Category(
      id: 'health-wellness',
      label: 'Health & wellness',
      glyph: '＋',
    ),
    BuyV2Category(id: 'dog-care', label: 'Dog care', glyph: '♡'),
    BuyV2Category(id: 'cat-care', label: 'Cat care', glyph: '♧'),
  ];

  static const medicineCategories = <BuyV2Category>[
    BuyV2Category(id: 'all', label: 'All', glyph: '☷'),
    BuyV2Category(id: 'rx', label: 'Prescription', glyph: 'Rx'),
    BuyV2Category(id: 'pain-fever', label: 'Pain & fever', glyph: '＋'),
    BuyV2Category(id: 'diabetes', label: 'Diabetes', glyph: '◒'),
    BuyV2Category(id: 'heart-bp', label: 'Heart & BP', glyph: '♥'),
    BuyV2Category(id: 'digestive', label: 'Digestive', glyph: '◇'),
    BuyV2Category(id: 'respiratory', label: 'Respiratory', glyph: '≈'),
    BuyV2Category(id: 'allergy', label: 'Allergy', glyph: '✦'),
    BuyV2Category(id: 'vitamins', label: 'Vitamins', glyph: 'V'),
    BuyV2Category(id: 'first-aid', label: 'First aid', glyph: '✚'),
    BuyV2Category(id: 'devices', label: 'Devices', glyph: '▣'),
    BuyV2Category(id: 'women-care', label: 'Women care', glyph: '○'),
    BuyV2Category(id: 'baby-care', label: 'Baby care', glyph: '◎'),
    BuyV2Category(id: 'skin-care', label: 'Skin care', glyph: '◐'),
  ];

  static final _commerceSeeds = buyV2CommerceSeedRows
      .trim()
      .split('\n')
      .map((row) => _BuyV2CommerceSeed.fromRow(row.trim()))
      .toList(growable: false);

  static final products = <BuyV2Product>[
    for (final seed in _commerceSeeds)
      _commerceProduct(seed, BuyV2Destination.shop),
    for (final seed in _commerceSeeds)
      _commerceProduct(seed, BuyV2Destination.wholesale),
    ..._medicineProducts,
  ];

  static BuyV2Product _commerceProduct(
    _BuyV2CommerceSeed seed,
    BuyV2Destination destination,
  ) {
    final wholesale = destination == BuyV2Destination.wholesale;
    final seller = wholesale ? seed.wholesaleSeller : seed.shopSeller;
    final sellerType = wholesale
        ? seed.wholesaleSellerType
        : seed.shopSellerType;
    final originCity = _supplierOrigin(seller, sellerType);
    return BuyV2Product(
      id: '${wholesale ? 'w' : 's'}-${seed.id}',
      canonicalId: seed.id,
      destination: destination,
      categoryId: wholesale ? seed.wholesaleCategory : seed.shopCategory,
      brand: seed.brand.toUpperCase(),
      title: seed.title,
      variant: _catalogueVariant(seed),
      pack: wholesale ? seed.wholesalePack : seed.shopPack,
      price: wholesale ? seed.wholesalePrice : seed.shopPrice,
      unitPrice: wholesale ? seed.wholesaleUnit : seed.shopUnit,
      badge: wholesale ? seed.wholesaleBadge : seed.shopBadge,
      seller: seller,
      sellerType: sellerType,
      deliveryPromise: wholesale
          ? _wholesalePromise(originCity)
          : _shopPromise(seed.shopDelivery),
      origin: wholesale
          ? '$originCity → Jodhpur 342003'
          : 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Confirmed 29 Jul',
      visualLabel: _visualLabel(seed.id.replaceAll('-', ' ')),
      visualKind: _visualKind(
        wholesale ? seed.wholesaleCategory : seed.shopCategory,
      ),
      minimumOrder: wholesale ? _minimumOrder(seed.id) : 1,
      returnPolicy: wholesale
          ? seed.wholesaleReturnPolicy
          : seed.shopReturnPolicy,
      freightIncluded: wholesale,
      manufacturerVerified:
          wholesale && sellerType.toLowerCase().contains('manufacturer'),
    );
  }

  static String _shopPromise(String source) {
    final minutes = RegExp(
      r'(\d+)\s+minutes',
      caseSensitive: false,
    ).firstMatch(source);
    if (minutes != null) {
      return 'Wed, 29 Jul · within ${minutes.group(1)} min';
    }
    final by = RegExp(r'by\s+(.+)$', caseSensitive: false).firstMatch(source);
    return 'Wed, 29 Jul · by ${by?.group(1) ?? '8:00 pm'}';
  }

  static String _wholesalePromise(String originCity) => switch (originCity) {
    'Delhi' => 'Sat, 1 Aug – Sun, 2 Aug',
    'Jaipur' => 'Fri, 31 Jul – Sat, 1 Aug',
    _ => 'Thu, 30 Jul',
  };

  static String _supplierOrigin(String seller, String sellerType) {
    final name = seller.toLowerCase();
    final type = sellerType.toLowerCase();
    if (const [
      'jodhpur',
      'sardarpura',
      'shree balaji',
      'ghar bazaar',
      'marwar',
      'thar',
      'family stationery',
      'school bazaar',
      'rajasthan mart',
    ].any(name.contains)) {
      return 'Jodhpur';
    }
    if (const [
          'surya oils',
          'care products',
          'herbal brands',
          'india',
          'national',
        ].any(name.contains) ||
        (type.contains('manufacturer') &&
            !name.contains('rajasthan') &&
            !name.contains('aravali'))) {
      return 'Delhi';
    }
    if (const ['rajasthan', 'aravali', 'kisan', 'jaipur'].any(name.contains)) {
      return 'Jaipur';
    }
    return 'Jodhpur';
  }

  static int _minimumOrder(String canonicalId) => switch (canonicalId) {
    'rice' => 4,
    'notebook' => 1,
    _ => 2,
  };

  static String _catalogueVariant(_BuyV2CommerceSeed seed) {
    const explicitVariants = {
      'tomato',
      'atta',
      'oil',
      'rice',
      'soap',
      'notebook',
      'banana',
      'potato',
      'curd',
      'paneer',
      'fish-fillet',
      'mutton',
      'toor-dal',
      'mustard-oil',
      'groundnut-oil',
      'red-chilli',
      'coriander-seeds',
      'thermal-rolls',
      'barcode-labels',
      'carry-bags',
      'printer-paper',
      'ball-pens',
    };
    if (explicitVariants.contains(seed.id)) return seed.variant;
    final separator = seed.variant.indexOf(' · ');
    if (separator < 0) return seed.variant;
    final descriptor = seed.variant.substring(0, separator);
    final titleCase = descriptor
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return '$titleCase${seed.variant.substring(separator)}';
  }

  static String _visualLabel(String value) {
    final words = value.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length == 1) {
      final end = words.first.length < 6 ? words.first.length : 6;
      return words.first.substring(0, end).toUpperCase();
    }
    return words.take(2).map((word) => word[0]).join().toUpperCase();
  }

  static String _visualKind(String category) {
    if (category.contains('fruit') || category.contains('vegetable')) {
      return 'produce';
    }
    if (category.contains('dairy') || category.contains('icecream')) {
      return 'bottle';
    }
    if (category.contains('oil') || category.contains('ghee')) return 'bottle';
    if (category.contains('paper') ||
        category.contains('stationery') ||
        category.contains('school')) {
      return 'paper';
    }
    return 'pack';
  }

  static const _medicineProducts = <BuyV2Product>[
    BuyV2Product(
      id: 'm-paracetamol-500',
      destination: BuyV2Destination.medicine,
      categoryId: 'pain-fever',
      brand: 'PAIN & FEVER · RELIEF 500',
      title: 'Paracetamol 500 mg tablets',
      variant: 'Paracetamol 500 mg',
      pack: 'Strip of 15 tablets',
      price: 28,
      mrp: 34,
      unitPrice: '₹1.87/tablet',
      badge: '18% off',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Expiry and batch shown before dispatch',
      visualLabel: '500',
      visualKind: 'medicine-box',
      composition: 'Paracetamol 500 mg',
      regulatoryNote: 'Use only as directed on the pack or by a clinician.',
      manufacturerVerified: true,
    ),
    BuyV2Product(
      id: 'm-pain-relief-gel',
      destination: BuyV2Destination.medicine,
      categoryId: 'pain-fever',
      brand: 'PAIN & FEVER · FLEXIRELIEF',
      title: 'Pain relief gel',
      variant: 'Diclofenac gel 1% w/w',
      pack: '30 g tube',
      price: 99,
      mrp: 118,
      unitPrice: '₹3.30/g',
      badge: '16% off',
      seller: 'Jodhpur Care Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Sealed tube',
      visualLabel: 'GEL',
      visualKind: 'tube',
      composition: 'Diclofenac gel 1% w/w',
      regulatoryNote: 'For external use only.',
    ),
    BuyV2Product(
      id: 'm-metformin-500',
      destination: BuyV2Destination.medicine,
      categoryId: 'diabetes',
      brand: 'DIABETES · GLYCO SR',
      title: 'Metformin SR 500 mg',
      variant: 'Metformin 500 mg sustained release',
      pack: 'Strip of 10 tablets',
      price: 29,
      mrp: 36,
      unitPrice: '₹2.90/tablet',
      badge: 'Prescription required',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: 'SR 500',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Metformin 500 mg sustained release',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-glucose-strips',
      destination: BuyV2Destination.medicine,
      categoryId: 'devices',
      brand: 'DIABETES · GLUCOCHECK',
      title: 'Blood glucose test strips',
      variant: 'Compatible capillary glucose strips',
      pack: 'Vial of 50 strips',
      price: 599,
      mrp: 690,
      unitPrice: '₹11.98/strip',
      badge: '13% off',
      seller: 'Marwar Wellness Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Check meter compatibility',
      visualLabel: '50',
      visualKind: 'bottle',
      composition: 'Capillary blood glucose test strips',
      regulatoryNote: 'Match the meter model before purchase.',
      manufacturerVerified: true,
    ),
    BuyV2Product(
      id: 'm-telmisartan-40',
      destination: BuyV2Destination.medicine,
      categoryId: 'heart-bp',
      brand: 'HEART & BP · TELMICARE 40',
      title: 'Telmisartan 40 mg tablets',
      variant: 'Telmisartan 40 mg',
      pack: 'Strip of 10 tablets',
      price: 86,
      mrp: 112,
      unitPrice: '₹8.60/tablet',
      badge: 'Prescription required',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: '40',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Telmisartan 40 mg',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-atorvastatin-10',
      destination: BuyV2Destination.medicine,
      categoryId: 'heart-bp',
      brand: 'HEART & BP · LIPICARE 10',
      title: 'Atorvastatin 10 mg tablets',
      variant: 'Atorvastatin 10 mg',
      pack: 'Strip of 10 tablets',
      price: 54,
      mrp: 74,
      unitPrice: '₹5.40/tablet',
      badge: 'Prescription required',
      seller: 'Marwar Wellness Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: '10',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Atorvastatin 10 mg',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-pantoprazole-40',
      destination: BuyV2Destination.medicine,
      categoryId: 'digestive',
      brand: 'DIGESTIVE · PANTOCARE 40',
      title: 'Pantoprazole 40 mg tablets',
      variant: 'Pantoprazole 40 mg',
      pack: 'Strip of 15 tablets',
      price: 69,
      mrp: 88,
      unitPrice: '₹4.60/tablet',
      badge: 'Prescription required',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Pharmacist review required',
      visualLabel: '40',
      visualKind: 'medicine-box',
      requiresPrescription: true,
      composition: 'Pantoprazole 40 mg',
      regulatoryNote: 'Dispensed only against a valid prescription.',
    ),
    BuyV2Product(
      id: 'm-ors',
      destination: BuyV2Destination.medicine,
      categoryId: 'digestive',
      brand: 'DIGESTIVE · HYDRAORS',
      title: 'ORS hydration salts',
      variant: 'Oral rehydration salts',
      pack: 'Pack of 5 sachets',
      price: 24,
      mrp: 30,
      unitPrice: '₹4.80/sachet',
      badge: '20% off',
      seller: 'Sardarpura Health Pharmacy',
      sellerType: 'Licensed pharmacy',
      deliveryPromise: 'Wed, 29 Jul · by 11:00 am',
      origin: 'Jodhpur → Sardarpura 342003',
      confirmedOn: 'Sealed single-use sachets',
      visualLabel: 'ORS',
      visualKind: 'tube',
      composition: 'Oral rehydration salts',
      regulatoryNote: 'Prepare with the stated amount of clean water.',
      manufacturerVerified: true,
    ),
  ];
}

extension BuyV2DestinationCopy on BuyV2Destination {
  String get label => switch (this) {
    BuyV2Destination.shop => 'Shop',
    BuyV2Destination.wholesale => 'Wholesale',
    BuyV2Destination.medicine => 'Medicine',
    BuyV2Destination.orders => 'Orders',
  };
}

extension BuyV2CartScopeCopy on BuyV2CartScope {
  String get label => switch (this) {
    BuyV2CartScope.all => '₹ Total',
    BuyV2CartScope.shop => 'Shop',
    BuyV2CartScope.wholesale => 'Wholesale',
    BuyV2CartScope.medicine => 'Medicine',
  };
}
