import 'package:flutter/material.dart';

import '../core/design/mool_theme.dart';
import '../features/book/book_session.dart';
import '../features/buy/buy_session.dart';
import '../features/chat/chat_session.dart';
import '../features/eat/eat_session.dart';
import '../features/journey01/journey_router.dart';
import '../features/journey01/journey_session.dart';
import '../features/ride/ride_session.dart';

class MoolSocialApp extends StatefulWidget {
  const MoolSocialApp({
    super.key,
    this.session,
    this.bookSession,
    this.buySession,
    this.chatSession,
    this.eatSession,
    this.rideSession,
    this.initialLocation = '/boot',
    this.disposeSession = false,
    this.disposeBookSession = false,
    this.disposeBuySession = false,
    this.disposeChatSession = false,
    this.disposeEatSession = false,
    this.disposeRideSession = false,
  });

  final JourneySession? session;
  final BookSession? bookSession;
  final BuySession? buySession;
  final ChatSession? chatSession;
  final EatSession? eatSession;
  final RideSession? rideSession;
  final String initialLocation;
  final bool disposeSession;
  final bool disposeBookSession;
  final bool disposeBuySession;
  final bool disposeChatSession;
  final bool disposeEatSession;
  final bool disposeRideSession;

  @override
  State<MoolSocialApp> createState() => _MoolSocialAppState();
}

class _MoolSocialAppState extends State<MoolSocialApp> {
  late final JourneySession _session = widget.session ?? JourneySession();
  late final BookSession _bookSession = widget.bookSession ?? BookSession();
  late final BuySession _buySession = widget.buySession ?? BuySession();
  late final ChatSession _chatSession = widget.chatSession ?? ChatSession();
  late final EatSession _eatSession = widget.eatSession ?? EatSession();
  late final RideSession _rideSession = widget.rideSession ?? RideSession();
  late final _router = createJourneyRouter(
    _session,
    _bookSession,
    _buySession,
    _chatSession,
    _eatSession,
    _rideSession,
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
    if (widget.chatSession == null || widget.disposeChatSession) {
      _chatSession.dispose();
    }
    if (widget.eatSession == null || widget.disposeEatSession) {
      _eatSession.dispose();
    }
    if (widget.rideSession == null || widget.disposeRideSession) {
      _rideSession.dispose();
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
