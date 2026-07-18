import 'package:flutter/material.dart';

import '../core/design/mool_theme.dart';
import '../features/journey01/journey_router.dart';
import '../features/journey01/journey_session.dart';

class MoolSocialApp extends StatefulWidget {
  const MoolSocialApp({
    super.key,
    this.session,
    this.initialLocation = '/boot',
    this.disposeSession = false,
  });

  final JourneySession? session;
  final String initialLocation;
  final bool disposeSession;

  @override
  State<MoolSocialApp> createState() => _MoolSocialAppState();
}

class _MoolSocialAppState extends State<MoolSocialApp> {
  late final JourneySession _session = widget.session ?? JourneySession();
  late final _router = createJourneyRouter(
    _session,
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    if (widget.session == null || widget.disposeSession) {
      _session.dispose();
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
