import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'recent searches stay bounded, destination-specific and restorable',
    () async {
      final store = _SearchStateStore();
      final core = BuySession();
      final session = BuyV2Session(core: core, customerStateStore: store);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      for (final value in const [
        'tomato',
        'milk',
        'atta',
        'soap',
        'bread',
        'coffee',
        'Tomato',
      ]) {
        expect(session.submitSearch(value), isTrue);
      }
      expect(session.recentSearchesFor(BuyV2Destination.shop), [
        'Tomato',
        'coffee',
        'bread',
        'soap',
        'atta',
        'milk',
      ]);

      session.openDestination(BuyV2Destination.wholesale);
      expect(session.submitSearch('bulk rice'), isTrue);
      expect(session.recentSearchesFor(BuyV2Destination.wholesale), [
        'bulk rice',
      ]);
      expect(session.recentSearchesFor(BuyV2Destination.shop), hasLength(6));

      session.openDestination(BuyV2Destination.medicine);
      expect(session.submitSearch('paracetamol'), isTrue);
      expect(session.recentSearchesFor(BuyV2Destination.medicine), isEmpty);
      await Future<void>.delayed(Duration.zero);

      final restoredCore = BuySession();
      final restored = BuyV2Session(
        core: restoredCore,
        customerStateStore: store,
      );
      addTearDown(restored.dispose);
      addTearDown(restoredCore.dispose);
      await restored.restoreCustomerState();
      expect(restored.recentSearchesFor(BuyV2Destination.shop).first, 'Tomato');
      expect(restored.recentSearchesFor(BuyV2Destination.wholesale), [
        'bulk rice',
      ]);
      expect(restored.recentSearchesFor(BuyV2Destination.medicine), isEmpty);
    },
  );

  testWidgets('keyboard Search commits, reuses and clears a recent query', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search products'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('buy-search-field'));
    expect(field, findsOneWidget);
    await tester.enterText(field, '  fresh   tomato  ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(session.query, 'fresh tomato');
    expect(session.recentSearchesFor(BuyV2Destination.shop), ['fresh tomato']);

    await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-recent-search-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buy-recent-search-0')));
    await tester.pumpAndSettle();
    expect(session.query, 'fresh tomato');

    await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-recent-searches-clear')));
    await tester.pumpAndSettle();
    expect(session.recentSearchesFor(BuyV2Destination.shop), isEmpty);
    expect(find.text('Recent searches'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final class _SearchStateStore implements BuyV2CustomerStateStore {
  BuyV2CustomerStateSnapshot? snapshot;

  @override
  String? get ownerScope => 'customer:search-recents';

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}
