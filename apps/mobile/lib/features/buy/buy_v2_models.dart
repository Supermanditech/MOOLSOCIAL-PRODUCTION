enum BuyV2Destination { shop, wholesale, medicine, orders }

enum BuyV2View { catalogue, product, cart, checkout, tracking, assist }

enum BuyV2CartScope { all, shop, wholesale, medicine }

enum BuyV2AddressKind { home, work, thirdParty, other }

enum BuyV2OrderStatus { preparing, confirmed, dispatched, arriving, delivered }

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
  });

  final String id;
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
}

class BuyV2CartLine {
  const BuyV2CartLine({required this.product, required this.quantity});

  final BuyV2Product product;
  final int quantity;

  int get total => product.price * quantity;

  BuyV2CartLine copyWith({int? quantity}) =>
      BuyV2CartLine(product: product, quantity: quantity ?? this.quantity);
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

  static final products = <BuyV2Product>[
    ..._commerceProducts(
      BuyV2Destination.shop,
      shopCategories.skip(1).toList(),
    ),
    ..._commerceProducts(
      BuyV2Destination.wholesale,
      wholesaleCategories.skip(1).toList(),
    ),
    ..._medicineProducts,
  ];

  static List<BuyV2Product> _commerceProducts(
    BuyV2Destination destination,
    List<BuyV2Category> categories,
  ) {
    const identity = <String, List<String>>{
      'fruits-vegetables': ['Fresh tomatoes', 'Red onions', 'Bananas'],
      'dairy-bakery': ['Toned fresh milk', 'Fresh paneer', 'Whole wheat bread'],
      'eggs-poultry': ['Farm eggs', 'Chicken curry cut', 'Free-range eggs'],
      'meat-seafood': ['Fresh fish fillets', 'Mutton curry cut', 'Prawns'],
      'flour-rice-grains': [
        'Stone-ground wheat atta',
        'Premium basmati rice',
        'Brown rice',
      ],
      'dals-staples': ['Toor dal', 'Sugar', 'Iodised salt'],
      'oils-ghee': ['Refined sunflower oil', 'Pure cow ghee', 'Mustard oil'],
      'retail-supplies': [
        'Thermal billing rolls',
        'Barcode labels',
        'Carry bags',
      ],
      'horeca-food-packs': [
        'Meal containers',
        'Aluminium foil',
        'Food storage tubs',
      ],
      'horeca-tableware': ['Paper cups', 'Dinner napkins', 'Wooden cutlery'],
      'stationery-office': [
        'A4 copier paper',
        'Smooth blue ball pens',
        'A4 notebooks',
      ],
      'school-office': ['A4 ruled notebooks', 'Blue ball pens', 'Drawing book'],
      'shop-supplies': [
        'Thermal billing rolls',
        'Price labels',
        'Barcode labels',
      ],
      'ground-spices': [
        'Ground turmeric',
        'Red chilli powder',
        'Coriander powder',
      ],
      'whole-spices': ['Cumin seeds', 'Black pepper', 'Whole cloves'],
      'breakfast-cereals': ['Rolled oats', 'Poha', 'Corn flakes'],
      'instant-foods': ['Instant noodles', 'Upma mix', 'Pasta'],
      'sauces-spreads': [
        'Tomato ketchup',
        'Peanut butter',
        'Green chilli sauce',
      ],
      'biscuits-chocolate': [
        'Glucose biscuits',
        'Dark chocolate',
        'Cream biscuits',
      ],
      'namkeen-chips': [
        'Classic bhujia namkeen',
        'Salted potato chips',
        'Roasted peanuts',
      ],
      'tea-coffee': ['Assam tea', 'Instant coffee', 'Masala tea'],
      'juices-water': ['Packaged water', 'Orange juice', 'Coconut water'],
      'frozen-foods': [
        'Frozen green peas',
        'Veg spring rolls',
        'Frozen paratha',
      ],
      'icecream-cheese': [
        'Vanilla ice cream',
        'Cheddar cheese',
        'Salted butter',
      ],
      'bath-hand-care': ['Herbal bathing soap', 'Hand wash', 'Body wash'],
      'oral-care': ['Fluoride toothpaste', 'Soft toothbrush', 'Mouthwash'],
      'hair-care': ['Daily care shampoo', 'Coconut hair oil', 'Conditioner'],
      'skin-care': ['Moisturising lotion', 'Face wash', 'Sunscreen'],
      'surface-cleaners': [
        'Floor cleaner',
        'Bathroom cleaner',
        'Glass cleaner',
      ],
      'air-waste-care': ['Garbage bags', 'Air freshener', 'Kitchen bin liners'],
      'laundry-dishwash': [
        'Laundry detergent',
        'Dishwash liquid',
        'Fabric conditioner',
      ],
      'diapers-wipes': ['Baby diapers', 'Baby wipes', 'Adult care pants'],
      'baby-care': ['Baby lotion', 'Baby cereal', 'Baby shampoo'],
      'health-wellness': [
        'ORS hydration salts',
        'Protein powder',
        'Herbal supplement',
      ],
      'dog-care': ['Adult dog food', 'Dog treats', 'Dog shampoo'],
      'cat-care': ['Adult cat food', 'Cat litter', 'Cat treats'],
      'food-storage-packs': [
        'Food storage bags',
        'Aluminium foil',
        'Cling film',
      ],
      'cups-tissues': ['Paper cups', 'Facial tissues', 'Kitchen towels'],
    };
    final wholesale = destination == BuyV2Destination.wholesale;
    return [
      for (
        var categoryIndex = 0;
        categoryIndex < categories.length;
        categoryIndex++
      )
        for (var productIndex = 0; productIndex < 3; productIndex++)
          BuyV2Product(
            id: '${wholesale ? 'w' : 's'}-${categories[categoryIndex].id}-$productIndex',
            destination: destination,
            categoryId: categories[categoryIndex].id,
            brand: wholesale ? 'TRADE ESSENTIALS' : 'DAILY ESSENTIALS',
            title:
                (identity[categories[categoryIndex].id] ??
                [
                  categories[categoryIndex].label,
                  '${categories[categoryIndex].label} value pack',
                  '${categories[categoryIndex].label} choice',
                ])[productIndex],
            variant: wholesale
                ? 'Verified trade pack · landed price'
                : 'Quality checked · sealed pack',
            pack: wholesale
                ? (productIndex == 0
                      ? 'Case pack · MOQ 2'
                      : 'Trade pack · MOQ 4')
                : (productIndex == 0 ? '500 g pack' : '1 family pack'),
            price: wholesale
                ? 580 + (categoryIndex * 83) + (productIndex * 190)
                : 37 + (categoryIndex * 9) + (productIndex * 28),
            unitPrice: wholesale
                ? 'Final landed unit price shown'
                : 'Final delivered unit price shown',
            badge: wholesale
                ? (productIndex == 0
                      ? 'Best landed cost'
                      : 'Manufacturer offer')
                : (productIndex == 0 ? 'Lowest delivered price' : 'Best value'),
            seller: wholesale
                ? (categoryIndex.isEven
                      ? 'Marwar Foods Distribution'
                      : 'Rajasthan Retail Supply')
                : (categoryIndex.isEven
                      ? 'Sardarpura Supermart'
                      : 'Jodhpur Fresh Mart'),
            sellerType: wholesale
                ? (categoryIndex.isEven
                      ? 'Verified distributor'
                      : 'Verified manufacturer')
                : 'Verified retailer',
            deliveryPromise: wholesale
                ? (categoryIndex.isEven
                      ? 'Thu, 30 Jul · by 2:00 pm'
                      : 'Fri, 31 Jul · by 5:00 pm')
                : (categoryIndex.isEven
                      ? 'Wed, 29 Jul · within 25 min'
                      : 'Wed, 29 Jul · by 7:30 pm'),
            origin: wholesale
                ? 'Jodhpur → Jodhpur 342003'
                : 'Jodhpur → Sardarpura 342003',
            confirmedOn: 'Confirmed 29 Jul',
            visualLabel: _visualLabel(
              (identity[categories[categoryIndex].id] ??
                  [
                    categories[categoryIndex].label,
                    categories[categoryIndex].label,
                    categories[categoryIndex].label,
                  ])[productIndex],
            ),
            visualKind: _visualKind(categories[categoryIndex].id),
            minimumOrder: wholesale ? 2 : 1,
          ),
    ];
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
