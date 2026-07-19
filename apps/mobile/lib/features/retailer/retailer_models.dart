import 'package:flutter/material.dart';

enum RetailerHomeView { home, orders, stock, wholesale }

extension RetailerHomeViewLabel on RetailerHomeView {
  String get label => switch (this) {
    RetailerHomeView.home => 'Home',
    RetailerHomeView.orders => 'Orders',
    RetailerHomeView.stock => 'Stock',
    RetailerHomeView.wholesale => 'Wholesale',
  };
}

enum RetailerOrderStage {
  newOrder,
  accepted,
  packing,
  packed,
  deliveryRequested,
  captainAssigned,
  parcelReady,
  captainArrived,
  handoverVerified,
  handedOver,
  outForDelivery,
  nearby,
  delivered,
  cannotFulfil,
}

extension RetailerOrderStageLabel on RetailerOrderStage {
  String get label => switch (this) {
    RetailerOrderStage.newOrder => 'Needs review',
    RetailerOrderStage.accepted => 'Accepted',
    RetailerOrderStage.packing => 'Packing',
    RetailerOrderStage.packed => 'Packed',
    RetailerOrderStage.deliveryRequested => 'Finding delivery',
    RetailerOrderStage.captainAssigned => 'Captain assigned',
    RetailerOrderStage.parcelReady => 'Parcel ready',
    RetailerOrderStage.captainArrived => 'Captain at shop',
    RetailerOrderStage.handoverVerified => 'Handover verified',
    RetailerOrderStage.handedOver => 'Handed to captain',
    RetailerOrderStage.outForDelivery => 'Out for delivery',
    RetailerOrderStage.nearby => 'Near customer',
    RetailerOrderStage.delivered => 'Delivered',
    RetailerOrderStage.cannotFulfil => 'Not fulfilled',
  };
}

class RetailerOrderLine {
  RetailerOrderLine({
    required this.id,
    required this.name,
    required this.detail,
    required this.quantity,
    required this.amount,
    this.packed = false,
  });

  final String id;
  final String name;
  final String detail;
  final int quantity;
  final int amount;
  bool packed;
}

class RetailerOrder {
  RetailerOrder({
    required this.id,
    required this.customer,
    required this.area,
    required this.payment,
    required this.fulfilment,
    required this.deliveryPromise,
    required this.amount,
    required this.lines,
    this.stage = RetailerOrderStage.newOrder,
  });

  final String id;
  final String customer;
  final String area;
  final String payment;
  final String fulfilment;
  final String deliveryPromise;
  final int amount;
  final List<RetailerOrderLine> lines;
  RetailerOrderStage stage;
  String? cannotFulfilReason;
  String? deliveryReference;
  String? captainName;
  String? captainVehicle;
  String? handoverReference;
  String? deliveryProof;
  String? issueReference;

  bool get allPacked => lines.every((line) => line.packed);
  int get packedCount => lines.where((line) => line.packed).length;
}

class RetailerAlert {
  const RetailerAlert({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

List<RetailerOrder> buildReviewRetailerOrders() => [
  RetailerOrder(
    id: 'MS-2841',
    customer: 'Amit Sharma',
    area: 'Sardarpura · 2.1 km',
    payment: 'Paid online · ₹1,240 protected',
    fulfilment: 'Home delivery',
    deliveryPromise: 'Deliver by 8:15 PM',
    amount: 1240,
    lines: [
      RetailerOrderLine(
        id: 'oil',
        name: 'Fortune Sunflower Oil',
        detail: '1 L pouch',
        quantity: 2,
        amount: 260,
      ),
      RetailerOrderLine(
        id: 'atta',
        name: 'Aashirvaad Whole Wheat Atta',
        detail: '5 kg pack',
        quantity: 1,
        amount: 310,
      ),
      RetailerOrderLine(
        id: 'salt',
        name: 'Tata Salt',
        detail: '1 kg pack',
        quantity: 2,
        amount: 56,
      ),
      RetailerOrderLine(
        id: 'remaining',
        name: '9 more products',
        detail: 'Packed as one checked group',
        quantity: 9,
        amount: 614,
      ),
    ],
  ),
  RetailerOrder(
    id: 'MS-2840',
    customer: 'Neha Jain',
    area: 'Ratanada · 3.4 km',
    payment: 'Cash after delivery · ₹486',
    fulfilment: 'Home delivery',
    deliveryPromise: 'Deliver by 8:40 PM',
    amount: 486,
    stage: RetailerOrderStage.delivered,
    lines: [
      RetailerOrderLine(
        id: 'basket',
        name: 'Fresh vegetable basket',
        detail: 'Family basket',
        quantity: 1,
        amount: 486,
        packed: true,
      ),
    ],
  )..deliveryProof = 'OTP received · 7:52 PM',
];

const retailerAlerts = [
  RetailerAlert(
    title: '1 order needs review',
    detail: 'MS-2841 is paid and waiting for acceptance.',
    icon: Icons.inventory_2_outlined,
  ),
  RetailerAlert(
    title: 'Delivery promise',
    detail: 'Pack MS-2841 before 7:45 PM to protect the 8:15 PM promise.',
    icon: Icons.schedule_rounded,
  ),
];
