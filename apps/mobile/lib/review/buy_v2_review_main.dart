import 'package:flutter/material.dart';

import '../core/design/mool_theme.dart';
import '../features/buy/buy_session.dart';
import '../features/buy/buy_v2_session.dart';
import '../ui_v2/buy/buy_v2_screen.dart';

/// Physical-device conformance harness for the founder-final Buy V2 module.
///
/// Production builds continue to enter through `main.dart`. This target mounts
/// the same native production widgets and state owner directly so screenshot,
/// accessibility and interruption checks can start at Buy without changing
/// account or launch state on the review device.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final core = BuySession();
  final session = BuyV2Session(core: core);
  runApp(_BuyV2ReviewApp(session: session));
}

class _BuyV2ReviewApp extends StatelessWidget {
  const _BuyV2ReviewApp({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoolSocial Buy',
      theme: MoolTheme.light(),
      home: BuyV2Screen(session: session),
    );
  }
}
