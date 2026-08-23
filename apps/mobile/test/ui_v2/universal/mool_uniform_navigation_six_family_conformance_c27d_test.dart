import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  testWidgets('C27D all real family and subaction states share one system', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await journey.start();
    addTearDown(journey.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        initialLocation: '/app/social?sub=shorts',
        disposeBookSession: true,
        disposeBuySession: true,
        disposeChatSession: true,
        disposeCreatorSession: true,
        disposeEatSession: true,
        disposeRideSession: true,
        disposeSharedSession: true,
        disposeWorkSession: true,
      ),
    );
    await tester.pumpAndSettle();

    await _expectFamily(tester, 'social', 'shorts');
    await _proveSwitcherAndDismiss(tester, 'social');
    for (final state in const [
      ('screen04-rail-videos', 'videos'),
      ('screen04-rail-feed', 'feed'),
    ]) {
      await _selectAndExpect(tester, state.$1, 'social', state.$2);
    }
    await tester.tap(find.byKey(const Key('screen04-rail-create')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('moolsocial-compact-destination-rail')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('screen04-create-close')));
    await tester.pumpAndSettle();
    await _expectFamily(tester, 'social', 'feed');
    await _selectAndExpect(tester, 'screen04-rail-shorts', 'social', 'shorts');

    await _openFamily(tester, 'buy');
    await _expectFamily(tester, 'buy', 'shop');
    for (final state in const [
      ('buy-local-tab-wholesale', 'wholesale'),
      ('buy-local-tab-orders', 'orders'),
    ]) {
      await _selectAndExpect(tester, state.$1, 'buy', state.$2);
    }
    expect(find.byKey(const Key('buy-local-tab-shop')), findsNothing);
    expect(find.text('Products'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('moolsocial-family-root-buy')));
    await tester.pumpAndSettle();
    await _expectFamily(tester, 'buy', 'shop');

    await _openFamily(tester, 'eat');
    await _expectFamily(tester, 'eat', 'order');
    await _selectAndExpect(tester, 'eat-local-table', 'eat', 'table');
    await _selectAndExpect(tester, 'eat-local-order', 'eat', 'order');

    await _openFamily(tester, 'ride');
    await _expectFamily(tester, 'ride', 'bike');
    await _selectAndExpect(tester, 'ride-local-auto', 'ride', 'auto');
    await _selectAndExpect(tester, 'ride-local-cab', 'ride', 'cab');
    await _selectAndExpect(tester, 'ride-local-bus', 'ride', 'bus');
    expect(
      find.byKey(const Key('travel-bus-local-navigation')),
      findsOneWidget,
    );
    await _selectAndExpect(tester, 'travel-local-bike', 'ride', 'bike');

    await _openFamily(tester, 'book');
    await _expectFamily(tester, 'book', 'doctor');
    await _selectAndExpect(tester, 'care-local-salon', 'book', 'salon');
    await _selectAndExpect(tester, 'care-local-medicine', 'book', 'medicine');
    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
    await _selectAndExpect(tester, 'care-local-tab-doctor', 'book', 'doctor');

    await _openFamily(tester, 'work');
    await _expectFamily(tester, 'work', 'earn');
    await _selectAndExpect(tester, 'work-local-workspace', 'work', 'workspace');
    await _selectAndExpect(tester, 'work-local-earn', 'work', 'earn');

    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectAndExpect(
  WidgetTester tester,
  String controlKey,
  String familyId,
  String selectedActionId,
) async {
  await tester.tap(find.byKey(Key(controlKey)));
  await tester.pumpAndSettle();
  await _expectFamily(tester, familyId, selectedActionId);
}

Future<void> _openFamily(WidgetTester tester, String familyId) async {
  await tester.tap(find.byKey(const Key('mool-compact-launcher')));
  await tester.pumpAndSettle();
  _expectSwitcher(tester, familyId: null);
  await tester.tap(find.byKey(ValueKey('mool-navigator-family-$familyId')));
  await tester.pumpAndSettle();
  expect(
    find.byKey(const Key('mool-connected-action-navigator')),
    findsNothing,
  );
}

Future<void> _proveSwitcherAndDismiss(
  WidgetTester tester,
  String familyId,
) async {
  await tester.tap(find.byKey(const Key('mool-compact-launcher')));
  await tester.pumpAndSettle();
  _expectSwitcher(tester, familyId: familyId);
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  expect(
    find.byKey(const Key('mool-connected-action-navigator')),
    findsNothing,
  );
  await _expectFamily(tester, familyId, 'shorts');
}

void _expectSwitcher(WidgetTester tester, {required String? familyId}) {
  final panel = find.byKey(const Key('mool-connected-action-navigator'));
  expect(panel, findsOneWidget);
  expect(tester.getSize(panel).width, MoolLocalNavigationTokens.switcherWidth);
  expect(find.byType(Dialog), findsNothing);
  for (final family in moolActionFamilies) {
    final row = find.byKey(ValueKey('mool-navigator-family-${family.id}'));
    expect(row, findsOneWidget);
    expect(
      tester.getSize(row).height,
      MoolLocalNavigationTokens.switcherRowHeight,
    );
  }
  if (familyId != null) {
    expect(
      find.byKey(ValueKey('mool-navigator-family-$familyId-indicator')),
      findsOneWidget,
    );
  }
}

Future<void> _expectFamily(
  WidgetTester tester,
  String familyId,
  String selectedActionId,
) async {
  final family = moolActionFamilyById(familyId);
  if (familyId == 'social') {
    expect(
      find.byKey(const Key('moolsocial-uniform-destination-canvas')),
      findsNothing,
    );
    final socialRail = find.byKey(
      const Key('moolsocial-compact-destination-rail'),
    );
    expect(socialRail, findsOneWidget);
    expect(
      tester.getSize(socialRail).height,
      MoolLocalNavigationTokens.destinationRailHeight,
    );
    final mool = find.byKey(const Key('mool-compact-launcher'));
    expect(
      tester.getSize(mool),
      Size(
        MoolLocalNavigationTokens.destinationFixedCellWidth,
        MoolLocalNavigationTokens.destinationRailHeight,
      ),
    );
    expect(find.byKey(const Key('social-global-chat')), findsOneWidget);
    const socialControls = <String, String>{
      'videos': 'screen04-rail-videos',
      'shorts': 'screen04-rail-shorts',
      'create': 'screen04-rail-create',
      'feed': 'screen04-rail-feed',
    };
    var previousCenterX = double.negativeInfinity;
    for (final entry in socialControls.entries) {
      final control = find.byKey(Key(entry.value));
      expect(control, findsOneWidget);
      expect(
        tester.getSemantics(control).rect.height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getSemantics(control).flagsCollection.isSelected,
        entry.key == selectedActionId ? Tristate.isTrue : Tristate.isFalse,
      );
      final centerX = tester.getCenter(control).dx;
      expect(centerX, greaterThan(previousCenterX));
      previousCenterX = centerX;
    }
    expect(tester.takeException(), isNull);
    return;
  }
  final canvas = tester.widget<DecoratedBox>(
    find.byKey(const Key('moolsocial-uniform-destination-canvas')),
  );
  final decoration = canvas.decoration as BoxDecoration;
  expect(decoration.color, MoolLocalNavigationTokens.destinationCanvas);
  expect(decoration.gradient, isNull);
  expect(decoration.boxShadow, isNull);
  expect(decoration.borderRadius, isNull);

  final rail = find.byKey(const Key('moolsocial-compact-destination-rail'));
  expect(rail, findsOneWidget);
  expect(
    tester.getSize(rail).height,
    MoolLocalNavigationTokens.destinationRailHeight,
  );
  expect(
    find.descendant(of: rail, matching: find.byType(Scrollable)),
    findsNothing,
  );
  expect(
    find.descendant(of: rail, matching: find.byType(BackdropFilter)),
    findsNothing,
  );

  final mool = find.byKey(const Key('mool-compact-launcher'));
  expect(
    tester.getSize(mool),
    Size(
      MoolLocalNavigationTokens.destinationFixedCellWidth,
      MoolLocalNavigationTokens.destinationRailHeight,
    ),
  );
  expect(
    find.byKey(const Key('mool-compact-launcher-icon-label')),
    findsOneWidget,
  );
  _expectLabelIsNotScaled(
    within: find.byKey(const Key('mool-compact-launcher-icon-label')),
    label: 'Mool',
  );

  final familyRoot = find.byKey(ValueKey('moolsocial-family-root-$familyId'));
  if (familyId == 'social') {
    expect(familyRoot, findsNothing);
  } else {
    expect(
      tester.getSize(familyRoot),
      Size(
        MoolLocalNavigationTokens.destinationFixedCellWidth,
        MoolLocalNavigationTokens.destinationRailHeight,
      ),
    );
    _expectLabelIsNotScaled(within: familyRoot, label: family.label);
  }

  var previousCenterX = double.negativeInfinity;
  for (final action in family.actions) {
    final control = find.byKey(
      ValueKey('moolsocial-local-${action.id}-selection'),
    );
    expect(control, findsOneWidget);
    final size = tester.getSize(control);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, MoolLocalNavigationTokens.destinationRailHeight);
    final centerX = tester.getCenter(control).dx;
    expect(centerX, greaterThan(previousCenterX));
    previousCenterX = centerX;

    final labelFinder = find.descendant(
      of: control,
      matching: find.text(action.label),
    );
    final label = tester.widget<Text>(labelFinder);
    expect(label.maxLines, 2);
    expect(label.style?.fontFamily, 'Inter');
    expect(
      label.style?.fontSize,
      MoolLocalNavigationTokens.destinationLabelSize,
    );
    expect(
      label.style?.fontWeight,
      action.id == selectedActionId ? FontWeight.w800 : FontWeight.w700,
    );
    expect(
      find.ancestor(of: labelFinder, matching: find.byType(FittedBox)),
      findsNothing,
    );

    final indicator = find.byKey(
      ValueKey('moolsocial-local-${action.id}-selected-indicator'),
    );
    expect(
      tester.getSize(indicator),
      Size(
        action.id == selectedActionId
            ? MoolLocalNavigationTokens.destinationSelectedIndicatorWidth
            : 0,
        MoolLocalNavigationTokens.destinationSelectedIndicatorHeight,
      ),
    );
  }

  final selectedIndicators = family.actions.where((action) {
    final indicator = find.byKey(
      ValueKey('moolsocial-local-${action.id}-selected-indicator'),
    );
    return tester.getSize(indicator).width > 0;
  });
  if (familyId == 'buy' && selectedActionId == 'shop') {
    expect(selectedIndicators, isEmpty);
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-buy')),
      findsOneWidget,
    );
  } else {
    expect(selectedIndicators.map((action) => action.id), [selectedActionId]);
  }
  expect(tester.takeException(), isNull);
}

void _expectLabelIsNotScaled({required Finder within, required String label}) {
  final text = find.descendant(of: within, matching: find.text(label));
  expect(text, findsOneWidget);
  expect(
    find.ancestor(of: text, matching: find.byType(FittedBox)),
    findsNothing,
  );
}
