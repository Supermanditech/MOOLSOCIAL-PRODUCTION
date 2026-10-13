/// Render contracts only. Values are explicit minor units, not tax calculation
/// or issuance authority. A backend adapter must validate provenance and scope.
enum CommerceInvoiceFormat { seller, platformFee, summary }

enum CommerceInvoicePartyRole { customer, retailer, supplier, platform }

class CommerceInvoiceTax {
  const CommerceInvoiceTax(this.label, this.rateBasisPoints, this.amountMinor);
  final String label;
  final int rateBasisPoints, amountMinor;
  String get rateLabel => '${(rateBasisPoints / 100).toStringAsFixed(2)}%';
  bool validFor(int taxable) =>
      const {'CGST', 'SGST', 'IGST', 'Cess'}.contains(label) &&
      rateBasisPoints >= 0 &&
      rateBasisPoints <= 10000 &&
      amountMinor >= 0 &&
      amountMinor <= commerceInvoiceMoneyLimit &&
      (amountMinor - (taxable * rateBasisPoints + 5000) ~/ 10000).abs() <= 1;
}

const commerceInvoiceMoneyLimit = 99999999999;

class CommerceInvoiceDocumentLine {
  CommerceInvoiceDocumentLine({
    required this.description,
    required this.quantity,
    required this.unitPriceMinor,
    this.pack = '',
    this.classification = '',
    this.discountMinor = 0,
    List<CommerceInvoiceTax> taxes = const [],
  }) : taxes = List.unmodifiable(taxes);
  final String description, pack, classification;
  final int quantity, unitPriceMinor, discountMinor;
  final List<CommerceInvoiceTax> taxes;
  int get grossMinor => quantity * unitPriceMinor;
  int get netMinor => grossMinor - discountMinor;
  int get taxMinor => taxes.fold(0, (sum, tax) => sum + tax.amountMinor);
  int get totalMinor => netMinor + taxMinor;
  bool get valid =>
      description.trim().isNotEmpty &&
      description.length <= 500 &&
      pack.length <= 120 &&
      classification.length <= 30 &&
      quantity > 0 &&
      quantity <= 1000000 &&
      unitPriceMinor >= 0 &&
      grossMinor <= commerceInvoiceMoneyLimit &&
      discountMinor >= 0 &&
      discountMinor <= grossMinor &&
      totalMinor <= commerceInvoiceMoneyLimit &&
      taxes.length <= 4 &&
      taxes.map((t) => t.label).toSet().length == taxes.length &&
      !(taxes.any((t) => t.label == 'IGST') &&
          taxes.any((t) => t.label == 'CGST' || t.label == 'SGST')) &&
      taxes.every((t) => t.validFor(netMinor));
}

class CommerceInvoiceAdjustment {
  const CommerceInvoiceAdjustment(this.kind, this.amountMinor);
  final CommerceInvoiceAdjustmentKind kind;
  final int amountMinor;
  String get label => switch (kind) {
    CommerceInvoiceAdjustmentKind.delivery => 'Delivery charges',
    CommerceInvoiceAdjustmentKind.platform => 'Platform fee (including tax)',
    CommerceInvoiceAdjustmentKind.deliveryDiscount => 'Delivery discount',
    CommerceInvoiceAdjustmentKind.coupon => 'Coupon discount',
    CommerceInvoiceAdjustmentKind.rounding => 'Round off',
  };
  bool get valid =>
      amountMinor.abs() <= commerceInvoiceMoneyLimit &&
      switch (kind) {
        CommerceInvoiceAdjustmentKind.delivery ||
        CommerceInvoiceAdjustmentKind.platform => amountMinor >= 0,
        CommerceInvoiceAdjustmentKind.deliveryDiscount ||
        CommerceInvoiceAdjustmentKind.coupon => amountMinor <= 0,
        CommerceInvoiceAdjustmentKind.rounding => amountMinor.abs() <= 100,
      };
}

enum CommerceInvoiceAdjustmentKind {
  delivery,
  platform,
  deliveryDiscount,
  coupon,
  rounding,
}

class CommerceInvoiceIssuer {
  const CommerceInvoiceIssuer({
    required this.legalName,
    required this.address,
    this.gstin = '',
    this.pan = '',
    this.cin = '',
    this.fssai = '',
    this.email = '',
    this.state = '',
    this.signatory = '',
    this.communicationAddress = '',
  });
  final String legalName,
      address,
      gstin,
      pan,
      cin,
      fssai,
      email,
      state,
      signatory,
      communicationAddress;
  Map<String, String> get fields => {
    'Legal name': legalName,
    'Address': address,
    'State': state,
    'Email': email,
    'GSTIN': gstin,
    'PAN': pan,
    'CIN': cin,
    'FSSAI': fssai,
  };
  bool get valid => [
    ...fields.values,
    signatory,
    communicationAddress,
  ].every((v) => v.length <= 2000);
}

/// Optional immutable document enrichment. Never construct from mutable Store
/// settings at download time or from unscoped public browsing data.
class CommerceInvoiceDocumentDetails {
  CommerceInvoiceDocumentDetails({
    required this.accountId,
    required this.storeId,
    required this.invoiceId,
    required this.orderId,
    required this.documentId,
    required this.sourceId,
    required this.format,
    required this.issuedAt,
    required this.issuer,
    required List<CommerceInvoiceDocumentLine> lines,
    required this.totalMinor,
    this.issuerRole = CommerceInvoicePartyRole.retailer,
    this.recipientRole = CommerceInvoicePartyRole.customer,
    Map<String, String> recipient = const {},
    this.sellerName = '',
    this.itemsSummary = '',
    this.paymentStatus = 'Payment status unavailable',
    this.itemBreakdownUnavailable = false,
    this.taxBreakdownProvided = false,
    this.placeOfSupply = '',
    this.reverseCharge,
    this.supplyStatement = '',
    this.terms = '',
    this.deliveryPartner = '',
    this.deliveryAddress = '',
    this.receivedMinor,
    this.paymentReference = '',
    List<CommerceInvoiceAdjustment> adjustments = const [],
  }) : lines = List.unmodifiable(lines),
       recipient = Map.unmodifiable(recipient),
       adjustments = List.unmodifiable(adjustments);
  final CommerceInvoicePartyRole issuerRole, recipientRole;
  final Map<String, String> recipient;
  final String sellerName, itemsSummary, paymentStatus;
  final bool itemBreakdownUnavailable;
  final String accountId, storeId, invoiceId, orderId, documentId, sourceId;
  final CommerceInvoiceFormat format;
  final DateTime issuedAt;
  final CommerceInvoiceIssuer issuer;
  final List<CommerceInvoiceDocumentLine> lines;
  final List<CommerceInvoiceAdjustment> adjustments;
  final int totalMinor;
  final int? receivedMinor;
  final bool taxBreakdownProvided;
  final bool? reverseCharge;
  final String placeOfSupply,
      supplyStatement,
      terms,
      deliveryPartner,
      deliveryAddress,
      paymentReference;
  int get grossMinor => itemBreakdownUnavailable
      ? totalMinor
      : lines.fold(0, (s, l) => s + l.grossMinor);
  int get discountMinor => lines.fold(0, (s, l) => s + l.discountMinor);
  int get taxMinor => lines.fold(0, (s, l) => s + l.taxMinor);
  bool get valid =>
      [
        accountId,
        storeId,
        invoiceId,
        orderId,
        documentId,
        sourceId,
      ].every((v) => v.trim().isNotEmpty && v.length <= 500) &&
      [
        placeOfSupply,
        supplyStatement,
        terms,
        deliveryPartner,
        deliveryAddress,
        paymentReference,
        sellerName,
        itemsSummary,
        paymentStatus,
      ].every((v) => v.length <= 2000) &&
      recipient.length <= 8 &&
      recipient.entries.every(
        (e) => e.key.length <= 80 && e.value.length <= 2000,
      ) &&
      (format != CommerceInvoiceFormat.platformFee ||
          issuerRole == CommerceInvoicePartyRole.platform) &&
      (format != CommerceInvoiceFormat.seller ||
          issuerRole == CommerceInvoicePartyRole.retailer ||
          issuerRole == CommerceInvoicePartyRole.supplier) &&
      issuer.valid &&
      (itemBreakdownUnavailable
          ? lines.isEmpty &&
                !taxBreakdownProvided &&
                adjustments.isEmpty &&
                format == CommerceInvoiceFormat.seller &&
                itemsSummary.trim().isNotEmpty
          : lines.isNotEmpty) &&
      lines.length <= 500 &&
      lines.every((l) => l.valid) &&
      adjustments.every((a) => a.valid) &&
      adjustments.map((a) => a.kind).toSet().length == adjustments.length &&
      (format == CommerceInvoiceFormat.summary ||
          adjustments.every(
            (a) => a.kind == CommerceInvoiceAdjustmentKind.rounding,
          )) &&
      totalMinor >= 0 &&
      totalMinor <= commerceInvoiceMoneyLimit &&
      (itemBreakdownUnavailable ||
          lines.fold<int>(0, (s, l) => s + l.totalMinor) +
                  adjustments.fold<int>(0, (s, a) => s + a.amountMinor) ==
              totalMinor) &&
      (receivedMinor == null ||
          receivedMinor! >= 0 && receivedMinor! <= totalMinor) &&
      (taxBreakdownProvided
          ? issuer.legalName.trim().isNotEmpty &&
                issuer.address.trim().isNotEmpty &&
                issuer.gstin.trim().isNotEmpty &&
                placeOfSupply.trim().isNotEmpty &&
                lines.every((l) => l.classification.trim().isNotEmpty)
          : lines.every((l) => l.taxes.isEmpty));
}

String commerceInvoiceMoney(int minor) =>
    '${minor < 0 ? '-' : ''}₹${minor.abs() ~/ 100}.${(minor.abs() % 100).toString().padLeft(2, '0')}';

String commerceInvoiceFileComponent(String id) {
  final safe = id
      .replaceAll(
        RegExp(r'[\x00-\x1F\x7F<>:"/\\|?*\u202A-\u202E\u2066-\u2069]'),
        '-',
      )
      .replaceAll(RegExp(r'[\s._-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return safe.isEmpty ? 'document' : String.fromCharCodes(safe.runes.take(64));
}

/// Integer-only Indian-number wording; amounts and words share the same total.
String commerceInvoiceAmountInWords(int minor) {
  if (minor < 0 || minor > commerceInvoiceMoneyLimit) {
    throw const FormatException('Unsupported invoice amount.');
  }
  const small = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  const tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];
  String words(int n) {
    if (n < 20) return small[n];
    if (n < 100) {
      return '${tens[n ~/ 10]}${n % 10 == 0 ? '' : ' ${small[n % 10]}'}';
    }
    for (final unit in const {
      10000000: 'Crore',
      100000: 'Lakh',
      1000: 'Thousand',
      100: 'Hundred',
    }.entries) {
      if (n >= unit.key) {
        return '${words(n ~/ unit.key)} ${unit.value}${n % unit.key == 0 ? '' : ' ${words(n % unit.key)}'}';
      }
    }
    return '';
  }

  return '${words(minor ~/ 100)} Rupees${minor % 100 == 0 ? '' : ' and ${words(minor % 100)} Paise'} Only';
}
