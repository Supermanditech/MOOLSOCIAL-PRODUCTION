import '../buy/buy_v2_content_contracts.dart';
import '../buy/buy_v2_models.dart';

/// Public product copy, distinct from pack facts, policies and private stock.
/// Text syntax is shared by the editor and quoted multiline CSV cells.
class WorkspaceProductContent {
  const WorkspaceProductContent({
    this.description = '',
    this.highlights = const [],
    this.specifications = const {},
  });
  final String description;
  final List<String> highlights;
  final Map<String, String> specifications;
  static const labels = {
    'description': 'Product description',
    'highlights': 'Highlights — one per line',
    'specifications': 'Specifications — one Name: value per line',
  };
  Map<String, String> get inputValues => {
    'description': description,
    'highlights': highlights.join('\n'),
    'specifications': specifications.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n'),
  };
  Map<String, Object?> toJson() => {
    'description': description,
    'highlights': highlights,
    'specifications': specifications,
  };
  bool get isEmpty =>
      description.isEmpty && highlights.isEmpty && specifications.isEmpty;
  static WorkspaceProductContent parse(
    Map<String, String> values, {
    WorkspaceProductContent existing = const WorkspaceProductContent(),
    bool preserveBlank = false,
  }) {
    String value(String key) {
      final text = (values[key] ?? '').trim();
      return preserveBlank && text.isEmpty ? existing.inputValues[key]! : text;
    }

    final description = value('description');
    if (description.length > 4000) {
      throw const FormatException('description: Use at most 4,000 characters.');
    }
    final highlights = value(
      'highlights',
    ).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (highlights.length > 20 || highlights.any((s) => s.length > 240)) {
      throw const FormatException(
        'highlights: Use up to 20 lines, each at most 240 characters.',
      );
    }
    final specs = <String, String>{};
    final seen = <String>{};
    for (final line in value(
      'specifications',
    ).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
      final colon = line.indexOf(':');
      if (colon <= 0 || line.substring(colon + 1).trim().isEmpty) {
        throw const FormatException(
          'specifications: Enter each specification as Name: value.',
        );
      }
      final key = line.substring(0, colon).trim();
      final text = line.substring(colon + 1).trim();
      if (key.length > 80 ||
          text.length > 500 ||
          specs.length >= 30 ||
          !seen.add(key.toLowerCase())) {
        throw const FormatException(
          'specifications: Use up to 30 unique names (80 characters) and values (500 characters).',
        );
      }
      specs[key] = text;
    }
    return WorkspaceProductContent(
      description: description,
      highlights: List.unmodifiable(highlights),
      specifications: Map.unmodifiable(specs),
    );
  }
}

/// The same input contract is used by catalogue review, manual entry and CSV.
class WorkspaceSellingInputs {
  const WorkspaceSellingInputs(
    this.measure,
    this.wholesale,
    this.retailEnabled,
  );
  final WorkspacePackMeasure? measure;
  final WorkspaceWholesaleOffer? wholesale;
  final bool retailEnabled;
  static const labels = {
    'quantityPerPack': 'Quantity in each selling pack',
    'quantityUnit': 'Quantity unit (kg, L or unit)',
    'unitsPerCase': 'Sealed units per case',
    'sellingChannels': 'Selling channels (retail, wholesale or both)',
    'wholesaleSaleType': 'Wholesale offer type (wholesale or bulk)',
    'wholesalePrice': 'Wholesale price per selling pack',
    'wholesaleMinimum': 'Wholesale minimum packs',
    'wholesaleIncrement': 'Wholesale quantity step',
    'wholesaleTiers': 'Quantity prices (packs:price; packs:price)',
  };
  static WorkspaceSellingInputs parse(
    Map<String, String> fields, {
    WorkspacePackMeasure? existingMeasure,
    WorkspaceWholesaleOffer? existingWholesale,
    bool existingRetailEnabled = true,
    bool clearBlankTiers = false,
  }) {
    String value(String key) => fields[key]?.trim() ?? '';
    var measure = existingMeasure;
    if ([
      'quantityPerPack',
      'quantityUnit',
      'unitsPerCase',
    ].any((key) => value(key).isNotEmpty)) {
      final quantity =
          value('quantityPerPack').isEmpty && existingMeasure != null
          ? existingMeasure.quantityText
          : value('quantityPerPack');
      if (!RegExp(r'^\d{1,6}(\.\d{1,3})?$').hasMatch(quantity)) {
        throw const FormatException(
          'quantityPerPack: enter a positive quantity with up to three decimal places.',
        );
      }
      final parts = quantity.split('.');
      final milli =
          int.parse(parts.first) * 1000 +
          int.parse(parts.length == 1 ? '0' : parts[1].padRight(3, '0'));
      final unitText = value('quantityUnit').isEmpty
          ? existingMeasure?.unitLabel ?? ''
          : value('quantityUnit');
      final unit = switch (unitText.toLowerCase()) {
        'kg' => BuyV2ComparisonUnit.kilogram,
        'l' => BuyV2ComparisonUnit.litre,
        'unit' => BuyV2ComparisonUnit.count,
        _ => null,
      };
      final cases = value('unitsPerCase').isEmpty
          ? existingMeasure?.unitsPerCase ?? 1
          : int.tryParse(value('unitsPerCase'));
      if (unit == null) {
        throw const FormatException('quantityUnit: choose kg, L or unit.');
      }
      if (cases == null) {
        throw const FormatException('unitsPerCase: enter a whole count.');
      }
      measure = WorkspacePackMeasure(
        unit: unit,
        quantityMilli: milli,
        unitsPerCase: cases,
        containedRetailUnitId: existingMeasure?.containedRetailUnitId,
      );
      if (!measure.valid) {
        throw const FormatException(
          'quantityPerPack: quantity and case count must be positive; unit counts must be whole.',
        );
      }
    }
    final channel = value('sellingChannels').toLowerCase();
    if (channel.isNotEmpty &&
        !['retail', 'wholesale', 'both'].contains(channel)) {
      throw const FormatException(
        'sellingChannels: choose retail, wholesale or both.',
      );
    }
    final retail = channel.isEmpty
        ? existingRetailEnabled
        : channel != 'wholesale';
    final enabled = channel.isEmpty
        ? existingWholesale?.enabled == true
        : channel != 'retail';
    var wholesale = existingWholesale;
    final saleTypeText = value('wholesaleSaleType').toLowerCase();
    final saleType = saleTypeText.isEmpty
        ? existingWholesale?.saleType
        : switch (saleTypeText) {
            'wholesale' => BuyV2WholesaleSaleType.wholesale,
            'bulk' => BuyV2WholesaleSaleType.bulk,
            _ => throw const FormatException(
              'wholesaleSaleType: choose wholesale or bulk.',
            ),
          };
    if (enabled ||
        [
          'wholesaleSaleType',
          'wholesalePrice',
          'wholesaleMinimum',
          'wholesaleIncrement',
          'wholesaleTiers',
        ].any((key) => value(key).isNotEmpty)) {
      int number(String key, int? fallback) {
        final parsed = value(key).isEmpty ? fallback : int.tryParse(value(key));
        final maximum = key == 'wholesalePrice' ? 999999999 : 999999;
        if (parsed == null || parsed <= 0 || parsed > maximum) {
          throw FormatException(
            '$key: enter a whole number from 1 to $maximum.',
          );
        }
        return parsed;
      }

      final price = number('wholesalePrice', existingWholesale?.priceRupees);
      final minimum = number(
        'wholesaleMinimum',
        existingWholesale?.minimumPacks ?? 1,
      );
      final increment = number(
        'wholesaleIncrement',
        existingWholesale?.incrementPacks ?? 1,
      );
      final tiers = <BuyV2ComparisonPriceTier>[];
      if (value('wholesaleTiers').isNotEmpty) {
        for (final pair in value('wholesaleTiers').split(';')) {
          final cells = pair.trim().split(':');
          final packs = cells.length == 2
              ? int.tryParse(cells[0].trim())
              : null;
          final amount = cells.length == 2
              ? int.tryParse(cells[1].trim())
              : null;
          if (packs == null || amount == null) {
            throw const FormatException(
              'wholesaleTiers: use packs:price separated by semicolons.',
            );
          }
          tiers.add(
            BuyV2ComparisonPriceTier(
              minimumPacks: packs,
              packPriceMinor: amount * 100,
            ),
          );
        }
      } else if (!clearBlankTiers || !fields.containsKey('wholesaleTiers')) {
        tiers.addAll(existingWholesale?.tiers ?? []);
      }
      wholesale = WorkspaceWholesaleOffer(
        priceRupees: price,
        minimumPacks: minimum,
        incrementPacks: increment,
        tiers: tiers,
        enabled: enabled,
        saleType: saleType,
      );
      if (!wholesale.valid) {
        throw const FormatException(
          'wholesaleTiers: check positive prices, minimum, quantity step and increasing tier quantities.',
        );
      }
    } else if (wholesale != null && channel == 'retail') {
      wholesale = WorkspaceWholesaleOffer(
        priceRupees: wholesale.priceRupees,
        minimumPacks: wholesale.minimumPacks,
        incrementPacks: wholesale.incrementPacks,
        tiers: wholesale.tiers,
        enabled: false,
        saleType: wholesale.saleType,
      );
    }
    return WorkspaceSellingInputs(measure, wholesale, retail);
  }
}

/// Exact quantity for one selling pack. Reuses Buy's comparison units/precision.
/// Display pack names are never parsed to manufacture this identity.
class WorkspacePackMeasure {
  const WorkspacePackMeasure({
    required this.unit,
    required this.quantityMilli,
    this.unitsPerCase = 1,
    this.containedRetailUnitId,
  });
  final BuyV2ComparisonUnit unit;
  final int quantityMilli, unitsPerCase;
  final String? containedRetailUnitId;
  String get quantityText {
    final whole = quantityMilli ~/ 1000;
    final fraction = (quantityMilli % 1000)
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? '$whole' : '$whole.$fraction';
  }

  bool get valid =>
      quantityMilli > 0 &&
      quantityMilli <= 999999999 &&
      unitsPerCase > 0 &&
      unitsPerCase <= 999999 &&
      (unit != BuyV2ComparisonUnit.count || quantityMilli % 1000 == 0);
  String get unitLabel => switch (unit) {
    BuyV2ComparisonUnit.kilogram => 'kg',
    BuyV2ComparisonUnit.litre => 'L',
    BuyV2ComparisonUnit.count => 'unit',
  };
  String pricePerUnit(int priceRupees) {
    if (!valid || priceRupees < 0 || priceRupees > 999999999) {
      throw const FormatException('Complete the pack quantity and price.');
    }
    // Whole-rupee legacy listing price -> exact minor units, half-up per unit.
    final minor = (priceRupees * 100000 + quantityMilli ~/ 2) ~/ quantityMilli;
    return '₹${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}/$unitLabel';
  }

  BuyV2ComparisonIdentity toComparison({
    required String specificationId,
    required String packId,
  }) => BuyV2ComparisonIdentity(
    specificationId: specificationId,
    packId: packId,
    unit: unit,
    packQuantityMilli: quantityMilli,
    containedRetailUnitId: containedRetailUnitId,
  );
  Map<String, Object?> toJson() => {
    'unit': unit.name,
    'quantityMilli': quantityMilli,
    'unitsPerCase': unitsPerCase,
    'containedRetailUnitId': containedRetailUnitId,
  };
  static WorkspacePackMeasure? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map ||
        raw['quantityMilli'] is! int ||
        raw['unitsPerCase'] is! int) {
      throw const FormatException('Invalid pack quantity.');
    }
    final unit = BuyV2ComparisonUnit.values
        .where((v) => v.name == raw['unit'])
        .firstOrNull;
    if (unit == null ||
        (raw['containedRetailUnitId'] != null &&
            raw['containedRetailUnitId'] is! String)) {
      throw const FormatException('Invalid pack unit.');
    }
    final result = WorkspacePackMeasure(
      unit: unit,
      quantityMilli: raw['quantityMilli'] as int,
      unitsPerCase: raw['unitsPerCase'] as int,
      containedRetailUnitId: raw['containedRetailUnitId'] as String?,
    );
    if (!result.valid) {
      throw const FormatException('Enter a positive pack quantity.');
    }
    return result;
  }
}

/// Retail and wholesale share inventory; only their selling terms differ.
/// Amounts here are explicitly whole rupees to match the current public product
/// model. Comparison conversion is *100, never truncated paise-as-rupees.
class WorkspaceWholesaleOffer {
  WorkspaceWholesaleOffer({
    required this.priceRupees,
    required this.minimumPacks,
    this.incrementPacks = 1,
    this.enabled = false,
    this.saleType,
    List<BuyV2ComparisonPriceTier> tiers = const [],
  }) : tiers = List.unmodifiable(tiers);
  final int priceRupees, minimumPacks, incrementPacks;
  final bool enabled;

  /// Explicit business classification, never inferred from pack, MOQ or price.
  /// Missing legacy values may remain private stock but are not publish-ready.
  final BuyV2WholesaleSaleType? saleType;
  final List<BuyV2ComparisonPriceTier> tiers;
  bool get valid {
    if (priceRupees <= 0 ||
        priceRupees > 999999999 ||
        minimumPacks <= 0 ||
        incrementPacks <= 0 ||
        minimumPacks > 999999 ||
        incrementPacks > 999999) {
      return false;
    }
    var previous = 0;
    var previousPrice = priceRupees * 100;
    for (final tier in tiers) {
      if (tier.minimumPacks < minimumPacks ||
          tier.minimumPacks <= previous ||
          (tier.minimumPacks - minimumPacks) % incrementPacks != 0 ||
          tier.packPriceMinor <= 0 ||
          tier.packPriceMinor % 100 != 0 ||
          tier.packPriceMinor > previousPrice) {
        return false;
      }
      previous = tier.minimumPacks;
      previousPrice = tier.packPriceMinor;
    }
    return true;
  }

  int priceAt(int packs) {
    if (!valid ||
        packs < minimumPacks ||
        (packs - minimumPacks) % incrementPacks != 0) {
      throw const FormatException('Choose a valid wholesale quantity.');
    }
    var amount = priceRupees;
    for (final tier in tiers) {
      if (packs >= tier.minimumPacks) amount = tier.packPriceMinor ~/ 100;
    }
    return amount;
  }

  Map<String, Object?> toJson() => {
    'priceRupees': priceRupees,
    'minimumPacks': minimumPacks,
    'incrementPacks': incrementPacks,
    'enabled': enabled,
    if (saleType != null) 'saleType': saleType!.name,
    'tiers': [
      for (final t in tiers)
        {'minimumPacks': t.minimumPacks, 'packPriceMinor': t.packPriceMinor},
    ],
  };
  static WorkspaceWholesaleOffer? fromJson(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map ||
        raw['priceRupees'] is! int ||
        raw['minimumPacks'] is! int ||
        raw['incrementPacks'] is! int ||
        raw['enabled'] is! bool ||
        raw['tiers'] is! List) {
      throw const FormatException('Invalid wholesale terms.');
    }
    final rawType = raw['saleType'];
    final saleType = switch (rawType) {
      null => null,
      'wholesale' => BuyV2WholesaleSaleType.wholesale,
      'bulk' => BuyV2WholesaleSaleType.bulk,
      _ => throw const FormatException('Invalid wholesale offer type.'),
    };
    final tiers = <BuyV2ComparisonPriceTier>[];
    for (final row in raw['tiers'] as List) {
      if (row is! Map ||
          row['minimumPacks'] is! int ||
          row['packPriceMinor'] is! int) {
        throw const FormatException('Invalid wholesale price tier.');
      }
      tiers.add(
        BuyV2ComparisonPriceTier(
          minimumPacks: row['minimumPacks'] as int,
          packPriceMinor: row['packPriceMinor'] as int,
        ),
      );
    }
    final result = WorkspaceWholesaleOffer(
      priceRupees: raw['priceRupees'] as int,
      minimumPacks: raw['minimumPacks'] as int,
      incrementPacks: raw['incrementPacks'] as int,
      enabled: raw['enabled'] as bool,
      saleType: saleType,
      tiers: tiers,
    );
    if (!result.valid) {
      throw const FormatException('Check wholesale price, quantity and tiers.');
    }
    return result;
  }
}

/// Retailer preference in the same vocabulary as Buy checkout. This is not an
/// approved customer credit grant, provider activation or a calculated quote.
class WorkspacePaymentTerm {
  const WorkspacePaymentTerm(this.kind, {this.advancePercent, this.netDays});
  final BuyV2CommercialPaymentTermKind kind;
  final int? advancePercent, netDays;
  static const wholesaleKinds = [
    BuyV2CommercialPaymentTermKind.wholesaleAdvance,
    BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch,
    BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
    BuyV2CommercialPaymentTermKind.paymentOnDelivery,
    BuyV2CommercialPaymentTermKind.supplierCredit,
  ];
  bool get needsAdvance =>
      kind == BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch ||
      kind == BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery;
  String get label => switch (kind) {
    BuyV2CommercialPaymentTermKind.retailAdvance =>
      'Full advance through MoolSocial',
    BuyV2CommercialPaymentTermKind.wholesaleAdvance => 'Full advance',
    BuyV2CommercialPaymentTermKind.bookingBalanceBeforeDispatch =>
      'Advance · balance before dispatch',
    BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery =>
      'Advance · balance at delivery',
    BuyV2CommercialPaymentTermKind.paymentOnDelivery => 'Payment at delivery',
    BuyV2CommercialPaymentTermKind.supplierCredit => 'Supplier credit',
    BuyV2CommercialPaymentTermKind.regulatedCredit => 'Lender finance',
  };
  bool get valid {
    if (!wholesaleKinds.contains(kind)) return false;
    if (needsAdvance) {
      return advancePercent != null &&
          advancePercent! > 0 &&
          advancePercent! < 100 &&
          netDays == null;
    }
    if (kind == BuyV2CommercialPaymentTermKind.supplierCredit) {
      return netDays != null &&
          netDays! > 0 &&
          netDays! <= 365 &&
          (advancePercent == null ||
              advancePercent! >= 0 && advancePercent! < 100);
    }
    return advancePercent == null && netDays == null;
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    if (advancePercent != null) 'advancePercent': advancePercent,
    if (netDays != null) 'netDays': netDays,
  };
  static WorkspacePaymentTerm fromJson(Map<String, Object?> json) {
    final kind = wholesaleKinds
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    if (kind == null ||
        json['advancePercent'] != null && json['advancePercent'] is! int ||
        json['netDays'] != null && json['netDays'] is! int) {
      throw const FormatException('Choose a supported wholesale payment term.');
    }
    final term = WorkspacePaymentTerm(
      kind,
      advancePercent: json['advancePercent'] as int?,
      netDays: json['netDays'] as int?,
    );
    if (!term.valid) {
      throw const FormatException(
        'Check the advance percentage and credit days.',
      );
    }
    return term;
  }

  static List<WorkspacePaymentTerm> decodeList(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) throw const FormatException('Choose payment terms.');
    final terms = raw.map((v) {
      if (v is! Map) throw const FormatException('Invalid payment term.');
      return fromJson(Map<String, Object?>.from(v));
    }).toList();
    if (terms.map((t) => t.kind).toSet().length != terms.length) {
      throw const FormatException('Choose each payment term only once.');
    }
    return List.unmodifiable(terms);
  }
}

/// Additional one-time provider inputs, NOT verification/quote/ledger outputs.
/// Existing Store ID/name/contact/GSTIN stay with their existing session owner.
class WorkspaceStorePublicationDetails {
  const WorkspaceStorePublicationDetails({
    this.businessType = 'retailer',
    this.retailChannelEnabled,
    this.wholesaleChannelEnabled,
    this.street = '',
    this.city = '',
    this.state = '',
    this.pinCode = '',
    this.legalName = '',
    this.billingAddress = '',
    this.pan = '',
    this.cin = '',
    this.fssai = '',
    this.signatory = '',
    this.retailPaymentMethods = const {},
    this.wholesalePaymentMethods = const {},
    this.wholesalePaymentTerms = const [],
    this.customerPaymentTerms = const {},
    this.returnSummary = '',
    this.returnWindowDays,
    this.returnConditions = '',
    this.returnRemedies = const {},
    this.dispatchDays = 0,
    this.shoppingArea,
  });
  static const businessTypes = {
    'retailer': 'Retailer / grocery',
    'wholesaler': 'Wholesaler',
    'manufacturer': 'Manufacturer',
    'supplier': 'Goods supplier',
  };
  final String businessType;
  // Null preserves older records' explicit per-SKU channel selections. Saving
  // Store preferences makes both values explicit, without rewriting inventory.
  final bool? retailChannelEnabled, wholesaleChannelEnabled;
  bool channelEnabled(BuyV2Destination channel) => switch (channel) {
    BuyV2Destination.shop => retailChannelEnabled ?? true,
    BuyV2Destination.wholesale => wholesaleChannelEnabled ?? true,
    _ => false,
  };
  String get publicSellerType => switch (businessType) {
    'wholesaler' => 'Wholesaler',
    'manufacturer' => 'Manufacturer',
    'supplier' => 'Supplier',
    _ => 'Store',
  };
  final String street,
      city,
      state,
      pinCode,
      legalName,
      billingAddress,
      pan,
      cin,
      fssai,
      signatory;
  final Set<String> retailPaymentMethods, wholesalePaymentMethods;
  final List<WorkspacePaymentTerm> wholesalePaymentTerms;

  /// Private Store/customer overrides: never attach this map to public products.
  /// Absence inherits defaults; an empty override explicitly allows no terms.
  final Map<String, List<WorkspacePaymentTerm>> customerPaymentTerms;
  List<WorkspacePaymentTerm> paymentTermsFor({
    required BuyV2Destination channel,
    String? customerId,
  }) => channel == BuyV2Destination.shop
      ? const [
          WorkspacePaymentTerm(BuyV2CommercialPaymentTermKind.retailAdvance),
        ]
      : channel == BuyV2Destination.wholesale
      ? List.unmodifiable(
          customerPaymentTerms[customerId] ?? wholesalePaymentTerms,
        )
      : const [];
  final String returnSummary;
  final int? returnWindowDays;
  final String returnConditions;
  final Set<String> returnRemedies;
  final int dispatchDays;
  static const retailMethods = {
    'PhonePe',
    'Paytm',
    'Pine Labs',
    'Cash on Delivery',
    'Purchase order',
  };
  static const wholesaleMethods = {
    'PhonePe',
    'Paytm',
    'Pine Labs',
    'UPI',
    'Bank transfer',
    'NEFT',
    'RTGS',
    'Cheque',
    'Cash',
    'Purchase order',
  };
  static const remedies = {'Replacement', 'Refund', 'Repair'};

  /// Input errors only. Missing data may remain a private draft. Location and
  /// service verification are separate publication requirements, never inferred.
  Map<String, String> get inputErrors => {
    if (!businessTypes.containsKey(businessType))
      'businessType': 'Choose a listed business type.',
    if ((retailChannelEnabled == null) != (wholesaleChannelEnabled == null))
      'sellingChannels': 'Set both Retail and Wholesale preferences.',
    if (wholesalePaymentTerms.any((t) => !t.valid) ||
        wholesalePaymentTerms.map((t) => t.kind).toSet().length !=
            wholesalePaymentTerms.length)
      'wholesalePaymentTerms': 'Check the wholesale payment terms.',
    if (customerPaymentTerms.entries.any(
      (e) =>
          e.key.trim().isEmpty ||
          e.value.any((t) => !t.valid) ||
          e.value.map((t) => t.kind).toSet().length != e.value.length,
    ))
      'customerPaymentTerms': 'Check the customer payment terms.',
    if (pinCode.isNotEmpty && !RegExp(r'^[1-9][0-9]{5}$').hasMatch(pinCode))
      'pinCode': 'Enter a valid six-digit PIN code.',
    if (dispatchDays < 0 || dispatchDays > 365)
      'dispatchDays': 'Enter dispatch time from 0 to 365 days.',
    if (returnWindowDays != null &&
        (returnWindowDays! < 0 || returnWindowDays! > 365))
      'returnWindowDays': 'Enter a return window from 0 to 365 days.',
    if (!retailMethods.containsAll(retailPaymentMethods))
      'retailPaymentMethods': 'Choose a listed retail payment method.',
    if (!wholesaleMethods.containsAll(wholesalePaymentMethods))
      'wholesalePaymentMethods': 'Choose a listed wholesale payment method.',
    if (!remedies.containsAll(returnRemedies))
      'returnRemedies': 'Choose replacement, refund or repair.',
    for (final entry in {
      'street': street,
      'city': city,
      'state': state,
      'legalName': legalName,
      'billingAddress': billingAddress,
      'pan': pan,
      'cin': cin,
      'fssai': fssai,
      'signatory': signatory,
      'returnSummary': returnSummary,
      'returnConditions': returnConditions,
    }.entries)
      if (entry.value.length > 2000)
        entry.key: 'Keep this information within 2,000 characters.',
  };

  Set<String> eligiblePaymentMethods({
    required BuyV2Destination channel,
    required Set<String> providerSupported,
    required Set<String> customerSupported,
  }) {
    final requested = switch (channel) {
      BuyV2Destination.shop => retailPaymentMethods,
      BuyV2Destination.wholesale => wholesalePaymentMethods,
      _ => const <String>{},
    };
    final allowed = channel == BuyV2Destination.shop
        ? retailMethods
        : wholesaleMethods;
    return Set.unmodifiable(
      requested
          .intersection(allowed)
          .intersection(providerSupported)
          .intersection(customerSupported),
    );
  }

  BuyV2PurchaseProtection? protectionFor(String? productOverride) {
    final override = productOverride?.trim() ?? '';
    // A SKU-specific override must not accidentally inherit contradictory
    // Store-level windows/remedies. Unspecified workflow fields stay absent.
    if (override.isNotEmpty && override != returnSummary.trim()) {
      return BuyV2PurchaseProtection(summary: override);
    }
    if (returnSummary.trim().isEmpty) return null;
    return BuyV2PurchaseProtection(
      summary: returnSummary.trim(),
      remedies: List.unmodifiable(returnRemedies.toList()..sort()),
      windowLabel: returnWindowDays == null
          ? null
          : '$returnWindowDays days from delivery',
      conditionsLabel: returnConditions.trim().isEmpty
          ? null
          : returnConditions.trim(),
    );
  }

  // Resolved by the location source, not a retailer-entered guessed region ID.
  final BuyV2ShoppingArea? shoppingArea;
  String get address => [
    street,
    city,
    state,
    pinCode,
  ].where((s) => s.trim().isNotEmpty).join(', ');
  List<String> get issues => [
    ...inputErrors.values,
    if (street.trim().isEmpty) 'Enter the Store street address.',
    if (city.trim().isEmpty || state.trim().isEmpty)
      'Enter the Store city and state.',
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(pinCode))
      'Enter a valid six-digit PIN code.',
    if (shoppingArea?.valid != true || shoppingArea?.postalCode != pinCode)
      'Confirm the Store location before publishing.',
    if (legalName.trim().isEmpty) 'Enter the legal business name for invoices.',
    if (dispatchDays < 0 || dispatchDays > 365)
      'Enter dispatch time from 0 to 365 days.',
    if (returnSummary.trim().isEmpty) 'Enter the Store return terms.',
  ];
  BuyV2StoreListing toPublicStore({
    required String id,
    required String name,
    required String area,
    BuyV2StoreCollectionCapability? collection,
  }) => BuyV2StoreListing(
    id: id,
    name: name,
    area: area,
    address: address,
    regionId: shoppingArea?.regionId ?? '',
    collection: collection?.storeId == id ? collection : null,
  );
  Map<String, Object?> toJson() => {
    'businessType': businessType,
    if (retailChannelEnabled != null)
      'retailChannelEnabled': retailChannelEnabled,
    if (wholesaleChannelEnabled != null)
      'wholesaleChannelEnabled': wholesaleChannelEnabled,
    'street': street,
    'city': city,
    'state': state,
    'pinCode': pinCode,
    'legalName': legalName,
    'billingAddress': billingAddress,
    'pan': pan,
    'cin': cin,
    'fssai': fssai,
    'signatory': signatory,
    'returnSummary': returnSummary,
    'returnWindowDays': returnWindowDays,
    'returnConditions': returnConditions,
    'returnRemedies': returnRemedies.toList()..sort(),
    'dispatchDays': dispatchDays,
    'retailPaymentMethods': retailPaymentMethods.toList()..sort(),
    'wholesalePaymentMethods': wholesalePaymentMethods.toList()..sort(),
    if (wholesalePaymentTerms.isNotEmpty)
      'wholesalePaymentTerms': wholesalePaymentTerms
          .map((t) => t.toJson())
          .toList(),
    if (customerPaymentTerms.isNotEmpty)
      'customerPaymentTerms': {
        for (final entry in customerPaymentTerms.entries)
          entry.key: entry.value.map((t) => t.toJson()).toList(),
      },
    if (shoppingArea case final a?)
      'shoppingArea': {
        'regionId': a.regionId,
        'googlePlaceId': a.googlePlaceId,
        'label': a.label,
        'countryCode': a.countryCode,
        'postalCode': a.postalCode,
      },
  };

  static WorkspaceStorePublicationDetails fromJson(Map<String, Object?> data) {
    bool? channelFlag(String key) {
      final value = data[key];
      if (value != null && value is! bool) {
        throw FormatException('$key: choose on or off.');
      }
      return value as bool?;
    }

    String text(String key) {
      final value = data[key];
      if (value != null && value is! String) {
        throw FormatException('$key: enter text.');
      }
      return (value as String? ?? '').trim();
    }

    int? count(String key, {int? fallback}) {
      final value = data[key];
      if (value == null) return fallback;
      if (value is! int) throw FormatException('$key: enter a whole number.');
      return value;
    }

    Set<String> choices(String key) {
      final value = data[key];
      if (value == null) return const {};
      if (value is! List || value.any((v) => v is! String)) {
        throw FormatException('$key: choose listed options.');
      }
      return Set.unmodifiable(value.cast<String>());
    }

    BuyV2ShoppingArea? area;
    final rawArea = data['shoppingArea'];
    if (rawArea != null) {
      if (rawArea is! Map ||
          [
            'regionId',
            'googlePlaceId',
            'label',
            'countryCode',
          ].any((key) => rawArea[key] is! String) ||
          rawArea['postalCode'] != null && rawArea['postalCode'] is! String) {
        throw const FormatException(
          'shoppingArea: invalid location reference.',
        );
      }
      area = BuyV2ShoppingArea(
        regionId: rawArea['regionId'] as String,
        googlePlaceId: rawArea['googlePlaceId'] as String,
        label: rawArea['label'] as String,
        countryCode: rawArea['countryCode'] as String,
        postalCode: rawArea['postalCode'] as String?,
      );
      if (!area.valid) {
        throw const FormatException(
          'shoppingArea: invalid location reference.',
        );
      }
    }
    final rawCustomerTerms = data['customerPaymentTerms'];
    if (rawCustomerTerms != null &&
        (rawCustomerTerms is! Map ||
            rawCustomerTerms.keys.any(
              (k) => k is! String || k.trim().isEmpty,
            ))) {
      throw const FormatException('Invalid customer payment terms.');
    }
    final value = WorkspaceStorePublicationDetails(
      businessType: data.containsKey('businessType')
          ? text('businessType')
          : 'retailer',
      retailChannelEnabled: channelFlag('retailChannelEnabled'),
      wholesaleChannelEnabled: channelFlag('wholesaleChannelEnabled'),
      street: text('street'),
      city: text('city'),
      state: text('state'),
      pinCode: text('pinCode'),
      legalName: text('legalName'),
      billingAddress: text('billingAddress'),
      pan: text('pan'),
      cin: text('cin'),
      fssai: text('fssai'),
      signatory: text('signatory'),
      retailPaymentMethods: choices('retailPaymentMethods'),
      wholesalePaymentMethods: choices('wholesalePaymentMethods'),
      wholesalePaymentTerms: WorkspacePaymentTerm.decodeList(
        data['wholesalePaymentTerms'],
      ),
      customerPaymentTerms: Map.unmodifiable({
        if (rawCustomerTerms is Map)
          for (final entry in rawCustomerTerms.entries)
            entry.key as String: WorkspacePaymentTerm.decodeList(entry.value),
      }),
      returnSummary: text('returnSummary'),
      returnConditions: text('returnConditions'),
      returnWindowDays: count('returnWindowDays'),
      returnRemedies: choices('returnRemedies'),
      dispatchDays: count('dispatchDays', fallback: 0)!,
      shoppingArea: area,
    );
    if (value.inputErrors.isNotEmpty) {
      final error = value.inputErrors.entries.first;
      throw FormatException('${error.key}: ${error.value}');
    }
    return value;
  }
}
