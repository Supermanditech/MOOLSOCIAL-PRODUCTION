import 'buy_models.dart';

class BuyServiceException implements Exception {
  const BuyServiceException(this.userMessage);

  final String userMessage;
}

abstract interface class BuyOrderGateway {
  Future<BuyOrderReceipt> placeOrder({
    required List<BuyCartLine> lines,
    required int total,
    required BuyFulfilment fulfilment,
    required String address,
    required String deliveryPromise,
    required BuyPaymentMethod paymentMethod,
  });
}

abstract interface class BuyMedicineGateway {
  Future<String> submitPrescription({required String productId});

  Future<String> requestPharmacist({required String question});
}

class ReviewBuyMedicineGateway implements BuyMedicineGateway {
  ReviewBuyMedicineGateway({
    this.failPrescription = false,
    this.failPharmacist = false,
    this.latency = const Duration(milliseconds: 120),
  });

  bool failPrescription;
  bool failPharmacist;
  final Duration latency;
  int prescriptionCalls = 0;
  int pharmacistCalls = 0;

  @override
  Future<String> submitPrescription({required String productId}) async {
    prescriptionCalls += 1;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failPrescription) {
      failPrescription = false;
      throw const BuyServiceException(
        'The prescription was not sent. No payment was taken. Try again.',
      );
    }
    return 'RX-${4100 + prescriptionCalls}';
  }

  @override
  Future<String> requestPharmacist({required String question}) async {
    pharmacistCalls += 1;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failPharmacist) {
      failPharmacist = false;
      throw const BuyServiceException(
        'Your question was not sent. Try again without losing the message.',
      );
    }
    return 'PH-${7300 + pharmacistCalls}';
  }
}

class ReviewBuyOrderGateway implements BuyOrderGateway {
  ReviewBuyOrderGateway({
    this.failNextRequest = false,
    this.latency = const Duration(milliseconds: 120),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool failNextRequest;
  final Duration latency;
  final DateTime Function() _now;
  int _sequence = 1041;

  @override
  Future<BuyOrderReceipt> placeOrder({
    required List<BuyCartLine> lines,
    required int total,
    required BuyFulfilment fulfilment,
    required String address,
    required String deliveryPromise,
    required BuyPaymentMethod paymentMethod,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (failNextRequest) {
      failNextRequest = false;
      throw const BuyServiceException(
        'Payment could not be completed. No money was deducted. Try again.',
      );
    }
    _sequence += 1;
    return BuyOrderReceipt(
      id: 'MS-BUY-$_sequence',
      createdAt: _now(),
      lines: List.unmodifiable(lines),
      total: total,
      fulfilment: fulfilment,
      address: address,
      deliveryPromise: deliveryPromise,
      paymentMethod: paymentMethod,
    );
  }
}
