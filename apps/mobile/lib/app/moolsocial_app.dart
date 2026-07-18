import 'package:flutter/material.dart';

import '../core/design/mool_theme.dart';
import '../features/buy/buy_session.dart';
import '../features/chat/chat_session.dart';
import '../features/eat/eat_session.dart';
import '../features/journey01/journey_router.dart';
import '../features/journey01/journey_session.dart';

class MoolSocialApp extends StatefulWidget {
  const MoolSocialApp({
    super.key,
    this.session,
    this.buySession,
    this.chatSession,
    this.eatSession,
    this.initialLocation = '/boot',
    this.disposeSession = false,
    this.disposeBuySession = false,
    this.disposeChatSession = false,
    this.disposeEatSession = false,
  });

  final JourneySession? session;
  final BuySession? buySession;
  final ChatSession? chatSession;
  final EatSession? eatSession;
  final String initialLocation;
  final bool disposeSession;
  final bool disposeBuySession;
  final bool disposeChatSession;
  final bool disposeEatSession;

  @override
  State<MoolSocialApp> createState() => _MoolSocialAppState();
}

class _MoolSocialAppState extends State<MoolSocialApp> {
  late final JourneySession _session = widget.session ?? JourneySession();
  late final BuySession _buySession = widget.buySession ?? BuySession();
  late final ChatSession _chatSession = widget.chatSession ?? ChatSession();
  late final EatSession _eatSession = widget.eatSession ?? EatSession();
  late final _router = createJourneyRouter(
    _session,
    _buySession,
    _chatSession,
    _eatSession,
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    if (widget.session == null || widget.disposeSession) {
      _session.dispose();
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
