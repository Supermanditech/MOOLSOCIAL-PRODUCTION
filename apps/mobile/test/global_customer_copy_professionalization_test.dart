import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shared customer surfaces contain no retained internal-state wording',
    () {
      const owners = <String>[
        'lib/ui_v2/buy/buy_v2_design.dart',
        'lib/ui_v2/buy/buy_v2_views.dart',
        'lib/ui_v2/social/social_v2_creator.dart',
        'lib/ui_v2/social/social_v2_plans_promotion.dart',
        'lib/features/work/screens/work_onboarding_screens.dart',
        'lib/features/work/work_services.dart',
        'lib/features/chat/chat_session.dart',
        'lib/features/chat/screens/chat_inbox_screen.dart',
        'lib/features/chat/screens/chat_archived_screen.dart',
        'lib/features/chat/screens/chat_settings_screen.dart',
        'lib/features/chat/screens/chat_thread_screen.dart',
        'lib/ui_v2/profile/global_profile_panel_v2.dart',
      ];
      const retiredCopy = <String>[
        'Ready to add',
        'Offer needs review',
        'Fulfilment unavailable',
        'Trade decision',
        "label: 'Decision'",
        'Local trade signal unavailable',
        'Checking local trade context',
        'Local trade context could not be loaded',
        'Retry local signal',
        'current trade facts',
        "label: 'Price source'",
        'provider-hosted video',
        'Connected-provider reports',
        'Provider metrics explain content performance',
        'proof source. Try another source',
        'for this app session',
      ];

      for (final owner in owners) {
        final source = File(owner).readAsStringSync();
        for (final copy in retiredCopy) {
          expect(
            source,
            isNot(contains(copy)),
            reason: '$owner exposes “$copy”',
          );
        }
      }
    },
  );

  test('replacement copy is actionable and customer-facing', () {
    final design = File('lib/ui_v2/buy/buy_v2_design.dart').readAsStringSync();
    final buy = File('lib/ui_v2/buy/buy_v2_views.dart').readAsStringSync();
    final chat = File(
      'lib/features/chat/screens/chat_settings_screen.dart',
    ).readAsStringSync();
    final work = File(
      'lib/features/work/screens/work_onboarding_screens.dart',
    ).readAsStringSync();

    expect(design, contains("statusLabel: 'Available now'"));
    expect(design, contains('Local market insight unavailable'));
    expect(buy, contains("title: 'Order details'"));
    expect(buy, contains('Check local insight again'));
    expect(chat, contains('reset when you close the app'));
    expect(work, contains('Choose how you want to add this document.'));
  });
}
