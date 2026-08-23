import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/universal/legacy_route_containment_screen_v2.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_choice_root_v2.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_projection_state_panel_v2.dart';
import 'package:moolsocial/ui_v2/universal/personal_mool_root_v2.dart';

void main() {
  final contractFile = File.fromUri(
    Directory.current.uri.resolve(
      '../../config/mvp-personal-copy-fitment-accessibility-v1.json',
    ),
  );
  final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
  final viewports = (contract['viewports'] as List).cast<Map>();
  final textScales = (contract['textScales'] as List).cast<num>();

  MediaQueryData mediaData(Size size, double textScale) => MediaQueryData(
    size: size,
    padding: const EdgeInsets.only(top: 24, bottom: 20),
    textScaler: TextScaler.linear(textScale),
    disableAnimations: textScale == 1.4,
    accessibleNavigation: textScale == 1.4,
  );

  Widget rootHost(Widget child, Size size, double textScale) => MaterialApp(
    theme: MoolTheme.light(),
    home: MediaQuery(data: mediaData(size, textScale), child: child),
  );

  Widget panelHost(Widget child, Size size, double textScale) => MaterialApp(
    theme: MoolTheme.light(),
    home: MediaQuery(
      data: mediaData(size, textScale),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );

  void expectNoTruncatedParagraphs(WidgetTester tester, String state) {
    for (final element in find.byType(RichText).evaluate()) {
      final renderObject = element.renderObject;
      if (renderObject is RenderParagraph) {
        expect(
          renderObject.didExceedMaxLines,
          isFalse,
          reason: '$state truncated: ${renderObject.text.toPlainText()}',
        );
      }
    }
  }

  void expectMinimumTarget(WidgetTester tester, Key key) {
    final size = tester.getSize(find.byKey(key));
    expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
    expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
  }

  Future<void> revealAboveDock(
    WidgetTester tester, {
    required Key target,
    required Finder scrollContainer,
    required double viewportHeight,
  }) async {
    final rect = tester.getRect(find.byKey(target));
    final visibleBottom = viewportHeight - 112;
    if (rect.bottom <= visibleBottom) return;
    await tester.drag(
      scrollContainer,
      Offset(0, -(rect.bottom - visibleBottom + 8)),
    );
    await tester.pumpAndSettle();
  }

  test('machine contract declares the exact independent matrix and owners', () {
    expect(viewports, [
      {'width': 320, 'height': 568},
      {'width': 360, 'height': 640},
      {'width': 360, 'height': 720},
      {'width': 375, 'height': 667},
      {'width': 390, 'height': 844},
      {'width': 412, 'height': 915},
      {'width': 430, 'height': 932},
    ]);
    expect(textScales, [1.0, 1.4]);
    expect(contract['matrixRows'], viewports.length * textScales.length);
    expect(contract['rootOwners'], [
      'PersonalMoolRootV2',
      'MvpActionChoiceRootV2:eat',
      'MvpActionChoiceRootV2:ride',
      'MvpActionChoiceRootV2:book',
      'MvpActionChoiceRootV2:work',
    ]);
    expect(contract['projectionStates'], [
      'loading',
      'held',
      'disabled',
      'stale',
      'offline',
      'denied',
    ]);
    expect(contract['legacyRecoveryReasons'], [
      'tiffin',
      'get-it-done',
      'standalone-pay',
      'delivery',
      'onboard',
      'verify',
    ]);
    expect(contract['requirements']['minimumTapTargetLogicalPixels'], 44);
    expect(contract['requirements']['artificialTextScaleCapAllowed'], isFalse);
    expect(
      contract['keyboardImeApplicability'],
      'not_applicable_no_input_surface',
    );
    expect(contract['newScreenOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newBackendOwners'], 0);
  });

  for (final viewport in viewports) {
    for (final scaleValue in textScales) {
      final size = Size(
        (viewport['width'] as num).toDouble(),
        (viewport['height'] as num).toDouble(),
      );
      final textScale = scaleValue.toDouble();
      final label =
          '${size.width.toInt()}x${size.height.toInt()}-text${(textScale * 100).round()}';

      testWidgets('$label fits every Personal exposure and recovery state', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          rootHost(
            PersonalMoolRootV2(
              onBack: () {},
              onOpenAction: (_) {},
              onOpenChat: () {},
            ),
            size,
            textScale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label mool');
        for (final family in moolActionFamilies) {
          final target = find.byKey(
            ValueKey('mool-home-family-${family.id}'),
          );
          expect(target, findsOneWidget);
          expect(find.text(family.label), findsOneWidget);
          expectNoTruncatedParagraphs(tester, '$label mool ${family.id}');
        }
        expect(find.text('Pay'), findsNothing);
        expectNoTruncatedParagraphs(tester, '$label mool');

        for (final entry in personalMvpActionChoiceRoots.entries) {
          final spec = entry.value;
          await tester.pumpWidget(
            rootHost(
              MvpActionChoiceRootV2(
                sectionLabel: spec.sectionLabel,
                headline: spec.headline,
                supportingText: spec.supportingText,
                actions: spec.actions,
                onBack: () {},
                onOpenAction: (_) {},
                onOpenMainAction: (_) {},
                onOpenMool: () {},
                onOpenChat: () {},
              ),
              size,
              textScale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$label ${entry.key}');
          expect(find.text(spec.headline), findsOneWidget);
          expect(find.text(spec.supportingText), findsOneWidget);
          for (final action in spec.actions) {
            await tester.scrollUntilVisible(
              find.byKey(Key('mvp-action-choice-${action.id}')),
              80,
              scrollable: find.descendant(
                of: find.byKey(Key('mvp-action-${entry.key}-list')),
                matching: find.byType(Scrollable),
              ),
            );
            expect(find.text(action.label), findsOneWidget);
            expect(find.text(action.supportingLabel), findsOneWidget);
            expectNoTruncatedParagraphs(
              tester,
              '$label ${entry.key} ${action.id}',
            );
          }
          expectNoTruncatedParagraphs(tester, '$label ${entry.key}');
        }

        for (final entry in mvpActionProjectionStateSpecs.entries) {
          await tester.pumpWidget(
            panelHost(
              MvpActionProjectionStatePanelV2(
                state: entry.key,
                onRetryProjection: () {},
                onReturnSafe: () {},
              ),
              size,
              textScale,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$label ${entry.value.id}',
          );
          expect(find.text(entry.value.title), findsOneWidget);
          expect(find.text(entry.value.detail), findsOneWidget);
          expectNoTruncatedParagraphs(tester, '$label ${entry.value.id}');
        }

        for (final entry in legacyRouteContainmentSpecs.entries) {
          await tester.pumpWidget(
            rootHost(
              LegacyRouteContainmentScreenV2(spec: entry.value),
              size,
              textScale,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$label legacy ${entry.key}',
          );
          expect(
            find.text('${entry.value.label} is not available here'),
            findsOneWidget,
          );
          expect(find.text(entry.value.detail), findsOneWidget);
          expectNoTruncatedParagraphs(tester, '$label legacy ${entry.key}');
        }
      });
    }
  }

  testWidgets('compact 140 percent actions are named sized and operable', (
    tester,
  ) async {
    const size = Size(320, 568);
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final openedMool = <String>[];
    var moolBack = 0;
    var moolChat = 0;
    await tester.pumpWidget(
      rootHost(
        PersonalMoolRootV2(
          onBack: () => moolBack += 1,
          onOpenAction: (_) {},
          onOpenChat: () => moolChat += 1,
          onOpenRoute: openedMool.add,
        ),
        size,
        1.4,
      ),
    );
    await tester.pumpAndSettle();
    for (final family in moolActionFamilies) {
      final key = ValueKey('mool-home-family-${family.id}');
      expect(find.bySemanticsLabel('Open ${family.label}'), findsOneWidget);
      expectMinimumTarget(tester, key);
      await tester.tap(find.byKey(key));
    }
    expect(find.byKey(const Key('mool-root-back')), findsNothing);
    expectMinimumTarget(tester, const Key('mool-home-chat'));
    await tester.binding.handlePopRoute();
    await tester.tap(find.byKey(const Key('mool-home-chat')));
    expect(openedMool, moolActionFamilies.map((family) => family.route));
    expect(moolBack, 1);
    expect(moolChat, 1);

    for (final entry in personalMvpActionChoiceRoots.entries) {
      final spec = entry.value;
      final opened = <String>[];
      var back = 0;
      var mool = 0;
      var chat = 0;
      await tester.pumpWidget(
        rootHost(
          MvpActionChoiceRootV2(
            sectionLabel: spec.sectionLabel,
            headline: spec.headline,
            supportingText: spec.supportingText,
            actions: spec.actions,
            onBack: () => back += 1,
            onOpenAction: (action) => opened.add(action.id),
            onOpenMainAction: (_) {},
            onOpenMool: () => mool += 1,
            onOpenChat: () => chat += 1,
          ),
          size,
          1.4,
        ),
      );
      await tester.pumpAndSettle();
      for (final action in spec.actions) {
        final key = Key('mvp-action-choice-${action.id}');
        final listKey = Key('mvp-action-${entry.key}-list');
        await tester.scrollUntilVisible(
          find.byKey(key),
          80,
          scrollable: find.descendant(
            of: find.byKey(listKey),
            matching: find.byType(Scrollable),
          ),
        );
        await revealAboveDock(
          tester,
          target: key,
          scrollContainer: find.byKey(listKey),
          viewportHeight: size.height,
        );
        expect(find.bySemanticsLabel('Open ${action.label}'), findsOneWidget);
        expectMinimumTarget(tester, key);
        await tester.tap(find.byKey(key));
      }
      final id = entry.key;
      const launcherKey = Key('mool-home-launcher');
      expectMinimumTarget(tester, launcherKey);
      expect(find.byKey(Key('mool-action-$id')), findsNothing);
      expect(find.byKey(const Key('mool-root-selected')), findsNothing);
      expect(find.byKey(const Key('mool-root-chat')), findsNothing);
      expect(find.byKey(Key('mvp-action-$id-back')), findsNothing);

      await tester.tap(find.byKey(launcherKey));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      const outsideDismissKey = Key('mool-switcher-outside-dismiss');
      final outsideDismissRect = tester.getRect(find.byKey(outsideDismissKey));
      await tester.tapAt(
        Offset(outsideDismissRect.right - 8, outsideDismissRect.top + 8),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(back, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(opened, spec.actions.map((action) => action.id));
      expect(back, 1);
      expect(mool, 0);
      expect(chat, 0);
    }

    var retries = 0;
    var safeReturns = 0;
    for (final entry in mvpActionProjectionStateSpecs.entries) {
      await tester.pumpWidget(
        panelHost(
          MvpActionProjectionStatePanelV2(
            state: entry.key,
            onRetryProjection: () => retries += 1,
            onReturnSafe: () => safeReturns += 1,
          ),
          size,
          1.4,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(entry.value.title))),
        findsOneWidget,
      );
      switch (entry.value.recovery) {
        case MvpActionProjectionRecovery.none:
          expect(find.byType(OutlinedButton), findsNothing);
        case MvpActionProjectionRecovery.retryProjection:
          const key = Key('mvp-projection-state-retry');
          expectMinimumTarget(tester, key);
          await tester.tap(find.byKey(key));
        case MvpActionProjectionRecovery.returnSafe:
          const key = Key('mvp-projection-state-return-safe');
          expectMinimumTarget(tester, key);
          await tester.tap(find.byKey(key));
      }
    }
    expect(retries, 2);
    expect(safeReturns, 3);

    for (final entry in legacyRouteContainmentSpecs.entries) {
      await tester.pumpWidget(
        rootHost(LegacyRouteContainmentScreenV2(spec: entry.value), size, 1.4),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Open ${entry.value.currentRootLabel}'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Open Mool'), findsOneWidget);
      expectMinimumTarget(tester, const Key('legacy-route-containment-back'));
      expectMinimumTarget(
        tester,
        const Key('legacy-route-containment-primary'),
      );
      if (entry.value.currentRootRoute == '/app/mool') {
        expect(
          find.byKey(const Key('legacy-route-containment-mool')),
          findsNothing,
        );
      } else {
        expectMinimumTarget(tester, const Key('legacy-route-containment-mool'));
      }
    }
    semantics.dispose();
  });
}
