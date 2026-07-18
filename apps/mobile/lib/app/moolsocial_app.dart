import 'package:flutter/material.dart';

import '../core/design/mool_theme.dart';
import '../features/journey01/journey_router.dart';
import '../features/journey01/journey_session.dart';

class MoolSocialApp extends StatefulWidget {
  const MoolSocialApp({super.key, this.session});

  final JourneySession? session;

  @override
  State<MoolSocialApp> createState() => _MoolSocialAppState();
}

class _MoolSocialAppState extends State<MoolSocialApp> {
  late final JourneySession _session =
      widget.session ?? JourneySession.development();
  late final _router = createJourneyRouter(_session);

  @override
  void dispose() {
    _router.dispose();
    if (widget.session == null) {
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
