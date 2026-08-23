import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = _repositoryRoot();
  final regressionFile = File(
    '${root.path}/config/mvp-personal-subaction-professional-recovery-regression-c20.json',
  );
  final regression =
      jsonDecode(regressionFile.readAsStringSync()) as Map<String, dynamic>;

  test(
    'aggregate contract locks six families and seventeen selected states',
    () {
      expect(regression['schemaVersion'], 1);
      expect(
        regression['contractId'],
        'UAW-PERSONAL-MVP-SUBACTION-PROFESSIONAL-RECOVERY-REGRESSION-C20',
      );
      expect(
        regression['state'],
        'c20h_r60_19_installed_checksum_matched_device_matrix_and_founder_acceptance_pending',
      );
      final families = regression['families'] as Map<String, dynamic>;
      expect(families.keys.toList(), [
        'social',
        'buy',
        'eat',
        'ride',
        'book',
        'work',
      ]);
      expect(
        families.values
            .expand((actions) => (actions as List<dynamic>))
            .toList(),
        hasLength(17),
      );
      expect(
        families.map((key, value) => MapEntry(key, (value as List).length)),
        {'social': 4, 'buy': 4, 'eat': 2, 'ride': 3, 'book': 2, 'work': 2},
      );

      final rules = regression['professionalGateRules'] as Map<String, dynamic>;
      expect(rules['childGateSequence'], ['C20B', 'C20C', 'C20D', 'C20E']);
      expect(rules['familyCount'], 6);
      expect(rules['selectedStateCount'], 17);
      expect(rules['supportedActionCounts'], [2, 3, 4]);
      expect(rules['selectedActionInert'], isTrue);
      expect(rules['availableActionOneTap'], isTrue);
      expect(rules['BackMoolChatContinuityRequired'], isTrue);
      expect(rules['contentReachabilityRequired'], isTrue);
      expect(rules['anchoredGlobalShellRequired'], isTrue);
      expect(rules['normalControlMotionMilliseconds'], 160);
      expect(rules['reducedMotionImmediate'], isTrue);
    },
  );

  test(
    'visual disclosure and overflow rules preserve professional grammar',
    () {
      final visual = regression['visualRules'] as Map<String, dynamic>;
      expect(visual['railSurfaceOpacity'], 0);
      expect(visual['individualNeutralGlassRequired'], isTrue);
      expect(visual['familyTintedFillAllowed'], isFalse);
      expect(visual['brandPaletteOnlyForSelection'], isTrue);
      expect(visual['minimumCompositedContrast'], 4.5);
      expect(visual['controlHeight'], 48);
      expect(visual['commonRadiusTarget'], 16);
      expect(visual['labelFontSizeTarget'], 13);
      expect(visual['labelFontWeightTarget'], 700);
      expect(visual['maximumTextScale'], 1.3);
      expect(visual['iconOpticalBoxTarget'], 20);
      expect(visual['supportedCounts'], [2, 3, 4]);
      for (final forbidden in const [
        'familyTintedFillAllowed',
        'backgroundBlockingBandAllowed',
        'horizontalSubactionScrollAllowed',
        'fillerActionAllowed',
      ]) {
        expect(visual[forbidden], isFalse, reason: forbidden);
      }

      final disclosure = regression['disclosureRules'] as Map<String, dynamic>;
      expect(disclosure['defaultExpanded'], isTrue);
      expect(disclosure['owner'], 'selected_main_action');
      expect(disclosure['targetMinimum'], 48);
      expect(disclosure['collapsedLayoutHeight'], 0);
      expect(disclosure['contentOrRouteResetAllowed'], isFalse);
      expect(disclosure['historyEntryAllowed'], isFalse);
      expect(disclosure['systemBackOverrideAllowed'], isFalse);
      expect(disclosure['reducedMotionImmediate'], isTrue);

      final overflow = regression['overflowRules'] as Map<String, dynamic>;
      expect(overflow['arrowGlyphMayBeIgnorePointer'], isFalse);
      expect(overflow['minimumTapTargetWhenArrowShown'], 44);
      expect(overflow['mayOverlapMainActionHitTargets'], isFalse);
      expect(
        overflow['exactPreviousNextSemanticsRequiredForInteractiveCue'],
        isTrue,
      );
    },
  );

  test('all required child gates tests and continuity owners exist', () {
    final required = <String>[
      ...(regression['requiredGates'] as List).cast<String>(),
      ...(regression['requiredTests'] as List).cast<String>(),
      ...(regression['requiredContinuityTests'] as List).cast<String>(),
    ];
    expect(required.toSet(), hasLength(required.length));
    for (final relative in required) {
      expect(
        File('${root.path}/$relative').existsSync(),
        isTrue,
        reason: relative,
      );
    }
    expect((regression['requiredGates'] as List).cast<String>().take(4), [
      'scripts/check-personal-subaction-disclosure-overflow-c20b.ps1',
      'scripts/check-personal-shared-neutral-brand-glass-control-c20c.ps1',
      'scripts/check-personal-social-buy-four-action-conformance-c20d.ps1',
      'scripts/check-personal-eat-ride-book-work-adaptive-conformance-c20e.ps1',
    ]);
  });

  test(
    'required source coverage owns semantics motion continuity and reachability',
    () {
      final coverage = <String, List<String>>{
        'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_subaction_disclosure_overflow_c20b_test.dart':
            [
              r'current. Hide $label options',
              r'current. Show $label options',
              "find.bySemanticsLabel('Previous main actions')",
              "find.bySemanticsLabel('Next main actions')",
            ],
        'apps/mobile/test/core/design/mool_neutral_brand_glass_local_navigation_c20c_test.dart':
            [
              'selectionColorForFamily(family)',
              'greaterThanOrEqualTo(4.5)',
              'Duration.zero',
            ],
        'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_social_buy_four_action_conformance_c20d_test.dart':
            [
              'const _widths = [320.0, 360.0, 390.0, 412.0, 430.0]',
              'flagsCollection.isSelected',
              'hasAction(SemanticsAction.tap)',
            ],
        'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_eat_ride_book_work_adaptive_conformance_c20e_test.dart':
            [
              "{'eat': 2, 'ride': 3, 'book': 2, 'work': 2}",
              'find.byType(Scrollable)',
              'find.byType(Expanded)',
            ],
        'apps/mobile/test/ui_v2/universal/uaw_personal_mvp_global_navigation_motion_containment_c10e_test.dart': [
          'deep Eat contextual switch and connected Work switch preserve one anchor',
          'Social connected self-route and Back keep exact ownership',
          'reduced motion changes destination without visual transition',
        ],
      };
      for (final entry in coverage.entries) {
        final source = File('${root.path}/${entry.key}').readAsStringSync();
        for (final token in entry.value) {
          expect(source, contains(token), reason: '${entry.key}: $token');
        }
      }

      final host = regression['hostQualification'] as Map<String, dynamic>;
      expect(host['requiredConsecutiveCycles'], 2);
      expect(host['completedConsecutiveCycles'], anyOf(0, 2));
      expect(host['unchangedSourceFingerprintRequired'], isTrue);
      expect(host['completeRequiredSuiteRequired'], isTrue);
      expect(host['buildAndInstallRemainClosed'], isTrue);
      expect(regression['buildAuthorized'], isFalse);
      expect(regression['installAuthorized'], isFalse);
    },
  );
}

Directory _repositoryRoot() {
  var cursor = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    if (File(
      '${cursor.path}/config/mvp-personal-subaction-professional-recovery-regression-c20.json',
    ).existsSync()) {
      return cursor;
    }
    cursor = cursor.parent;
  }
  throw StateError('MoolSocial production repository root was not found.');
}
