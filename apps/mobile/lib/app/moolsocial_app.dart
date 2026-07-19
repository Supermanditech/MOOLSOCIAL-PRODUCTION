import 'package:flutter/material.dart';

import '../core/design/mool_theme.dart';
import '../features/book/book_session.dart';
import '../features/buy/buy_session.dart';
import '../features/captain/captain_session.dart';
import '../features/chat/chat_session.dart';
import '../features/creator/creator_session.dart';
import '../features/eat/eat_session.dart';
import '../features/journey01/journey_router.dart';
import '../features/journey01/journey_session.dart';
import '../features/manufacturer/manufacturer_session.dart';
import '../features/operations/operations_session.dart';
import '../features/pay/pay_session.dart';
import '../features/retailer/retailer_session.dart';
import '../features/ride/ride_session.dart';
import '../features/shared/shared_session.dart';
import '../features/work/work_session.dart';

class MoolSocialApp extends StatefulWidget {
  const MoolSocialApp({
    super.key,
    this.session,
    this.bookSession,
    this.buySession,
    this.captainSession,
    this.chatSession,
    this.creatorSession,
    this.eatSession,
    this.manufacturerSession,
    this.operationsSession,
    this.paySession,
    this.retailerSession,
    this.rideSession,
    this.sharedSession,
    this.workSession,
    this.initialLocation = '/boot',
    this.disposeSession = false,
    this.disposeBookSession = false,
    this.disposeBuySession = false,
    this.disposeCaptainSession = false,
    this.disposeChatSession = false,
    this.disposeCreatorSession = false,
    this.disposeEatSession = false,
    this.disposeManufacturerSession = false,
    this.disposeOperationsSession = false,
    this.disposePaySession = false,
    this.disposeRetailerSession = false,
    this.disposeRideSession = false,
    this.disposeSharedSession = false,
    this.disposeWorkSession = false,
  });

  final JourneySession? session;
  final BookSession? bookSession;
  final BuySession? buySession;
  final CaptainSession? captainSession;
  final ChatSession? chatSession;
  final CreatorSession? creatorSession;
  final EatSession? eatSession;
  final ManufacturerSession? manufacturerSession;
  final OperationsSession? operationsSession;
  final PaySession? paySession;
  final RetailerSession? retailerSession;
  final RideSession? rideSession;
  final SharedSession? sharedSession;
  final WorkSession? workSession;
  final String initialLocation;
  final bool disposeSession;
  final bool disposeBookSession;
  final bool disposeBuySession;
  final bool disposeCaptainSession;
  final bool disposeChatSession;
  final bool disposeCreatorSession;
  final bool disposeEatSession;
  final bool disposeManufacturerSession;
  final bool disposeOperationsSession;
  final bool disposePaySession;
  final bool disposeRetailerSession;
  final bool disposeRideSession;
  final bool disposeSharedSession;
  final bool disposeWorkSession;

  @override
  State<MoolSocialApp> createState() => _MoolSocialAppState();
}

class _MoolSocialAppState extends State<MoolSocialApp> {
  late final JourneySession _session = widget.session ?? JourneySession();
  late final BookSession _bookSession = widget.bookSession ?? BookSession();
  late final BuySession _buySession = widget.buySession ?? BuySession();
  late final CaptainSession _captainSession =
      widget.captainSession ?? CaptainSession();
  late final ChatSession _chatSession = widget.chatSession ?? ChatSession();
  late final CreatorSession _creatorSession =
      widget.creatorSession ?? CreatorSession();
  late final EatSession _eatSession = widget.eatSession ?? EatSession();
  late final ManufacturerSession _manufacturerSession =
      widget.manufacturerSession ?? ManufacturerSession();
  late final OperationsSession _operationsSession =
      widget.operationsSession ?? OperationsSession();
  late final PaySession _paySession = widget.paySession ?? PaySession();
  late final RetailerSession _retailerSession =
      widget.retailerSession ?? RetailerSession();
  late final RideSession _rideSession = widget.rideSession ?? RideSession();
  late final SharedSession _sharedSession =
      widget.sharedSession ?? SharedSession();
  late final WorkSession _workSession = widget.workSession ?? WorkSession();
  late final _router = createJourneyRouter(
    _session,
    _bookSession,
    _buySession,
    _captainSession,
    _chatSession,
    _creatorSession,
    _eatSession,
    _manufacturerSession,
    _operationsSession,
    _paySession,
    _retailerSession,
    _rideSession,
    _sharedSession,
    _workSession,
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    if (widget.session == null || widget.disposeSession) {
      _session.dispose();
    }
    if (widget.bookSession == null || widget.disposeBookSession) {
      _bookSession.dispose();
    }
    if (widget.buySession == null || widget.disposeBuySession) {
      _buySession.dispose();
    }
    if (widget.captainSession == null || widget.disposeCaptainSession) {
      _captainSession.dispose();
    }
    if (widget.chatSession == null || widget.disposeChatSession) {
      _chatSession.dispose();
    }
    if (widget.creatorSession == null || widget.disposeCreatorSession) {
      _creatorSession.dispose();
    }
    if (widget.eatSession == null || widget.disposeEatSession) {
      _eatSession.dispose();
    }
    if (widget.manufacturerSession == null ||
        widget.disposeManufacturerSession) {
      _manufacturerSession.dispose();
    }
    if (widget.operationsSession == null || widget.disposeOperationsSession) {
      _operationsSession.dispose();
    }
    if (widget.paySession == null || widget.disposePaySession) {
      _paySession.dispose();
    }
    if (widget.retailerSession == null || widget.disposeRetailerSession) {
      _retailerSession.dispose();
    }
    if (widget.rideSession == null || widget.disposeRideSession) {
      _rideSession.dispose();
    }
    if (widget.sharedSession == null || widget.disposeSharedSession) {
      _sharedSession.dispose();
    }
    if (widget.workSession == null || widget.disposeWorkSession) {
      _workSession.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MoolSocial',
      theme: MoolTheme.light(),
      routerConfig: _router,
    );
  }
}
