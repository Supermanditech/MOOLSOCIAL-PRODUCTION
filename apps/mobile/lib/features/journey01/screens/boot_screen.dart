import 'package:flutter/material.dart';

import '../../../core/design/mool_theme.dart';
import '../journey_session.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({required this.session, super.key});

  final JourneySession session;

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      const Duration(milliseconds: 250),
      widget.session.completeBoot,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoolColors.navy,
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: 'MoolSocial is opening',
            liveRegion: true,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MoolSocial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Your social and economic world',
                  style: TextStyle(color: Color(0xFFD4D8FF), fontSize: 15),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: MoolColors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
