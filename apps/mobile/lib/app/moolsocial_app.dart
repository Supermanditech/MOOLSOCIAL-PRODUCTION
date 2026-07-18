import 'package:flutter/material.dart';

import '../core/design/mool_theme.dart';
import '../features/buy/buy_session.dart';
import '../features/chat/chat_session.dart';
import '../features/journey01/journey_router.dart';
import '../features/journey01/journey_session.dart';

class MoolSocialApp extends StatefulWidget {
  const MoolSocialApp({
    super.key,
    this.session,
    this.buySession,
    this.chatSession,
    this.initialLocation = '/boot',
    this.disposeSession = false,
    this.disposeBuySession = false,
    this.disposeChatSession = false,
  });

  final JourneySession? session;
  final BuySession? buySession;
  final ChatSession? chatSession;
  final String initialLocation;
  final bool disposeSession;
  final bool disposeBuySession;
  final bool disposeChatSession;

  @override
  State<MoolSocialApp> createState() => _MoolSocialAppState();
}

class _MoolSocialAppState extends State<MoolSocialApp> {
  late final JourneySession _session = widget.session ?? JourneySession();
  late final BuySession _buySession = widget.buySession ?? BuySession();
  late final ChatSession _chatSession = widget.chatSession ?? ChatSession();
  late final _router = createJourneyRouter(
    _session,
    _buySession,
    _chatSession,
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
