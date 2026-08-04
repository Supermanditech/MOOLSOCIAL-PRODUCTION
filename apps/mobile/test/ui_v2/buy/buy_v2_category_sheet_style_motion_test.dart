import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_category_sheet_policy.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(
        session,
        disableAnimations: disableAnimations,
        textScale: textScale,
        viewInsets: viewInsets,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('R56.3 reuses exact R40.3 route timing and immediate reduction', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2CategorySheetPolicy.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2CategorySheetPolicy.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, BuyV2CategorySheetPolicy.forwardDuration);
    expect(normal.reverseDuration, BuyV2CategorySheetPolicy.reverseDuration);
    expect(normal.duration, const Duration(milliseconds: 260));
    expect(normal.reverseDuration, const Duration(milliseconds: 260));
    expect(normal.curve, Curves.easeOutCubic);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
  });

  testWidgets('R58.8.8 expands only for a genuine keyboard inset', (
    tester,
  ) async {
    late double normal;
    late double keyboard;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2CategorySheetPolicy.heightFactorFor(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
              ),
              child: Builder(
                builder: (context) {
                  keyboard = BuyV2CategorySheetPolicy.heightFactorFor(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal, BuyV2CategorySheetPolicy.heightFactor);
    expect(normal, .64);
    expect(keyboard, 1);
  });

  testWidgets('R56.3 changes category only after the reverse route completes', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);
    final target = session.categories[1];
    expect(session.selectedCategoryId, 'all');

    await tester.tap(find.byKey(ValueKey('buy-category-${target.id}')));
    await tester.pump();
    expect(session.selectedCategoryId, 'all');
    await tester.pump(const Duration(milliseconds: 259));
    expect(session.selectedCategoryId, 'all');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, target.id);
    expect(
      find.byKey(const ValueKey('buy-category-sheet-route')),
      findsNothing,
    );
  });

  testWidgets('R56.3 Back and close preserve the selected category', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final initial = session.selectedCategoryId;
    await openSheet(tester, session);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, initial);
    expect(
      find.byKey(const ValueKey('buy-category-sheet-route')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-category-close')));
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, initial);
    expect(
      find.byKey(const ValueKey('buy-category-sheet-route')),
      findsNothing,
    );
  });

  testWidgets(
    'R56.3 named route, persistent field and selected semantics agree',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await openSheet(tester, session);

      expect(find.byKey(const ValueKey('buy-category-sheet-title')), findsOne);
      expect(find.text('Shop categories'), findsOneWidget);
      expect(find.bySemanticsLabel('Shop categories'), findsWidgets);
      final route = find.byKey(const ValueKey('buy-category-sheet-route'));
      final repaintBoundary = find.byKey(
        const ValueKey('buy-category-sheet-repaint-boundary'),
      );
      expect(repaintBoundary, findsOneWidget);
      expect(
        find.descendant(of: route, matching: repaintBoundary),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: repaintBoundary,
          matching: find.byKey(const ValueKey('buy-category-close')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: repaintBoundary,
          matching: find.byKey(const ValueKey('buy-category-search')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: repaintBoundary,
          matching: find.byKey(const ValueKey('buy-category-grid')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: repaintBoundary,
          matching: find.byKey(
            const ValueKey('buy-category-sheet-backdrop-owner'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-category-sheet-backdrop-blur')),
        findsNothing,
      );
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('buy-category-search')),
      );
      expect(field.decoration?.label, isA<ExcludeSemantics>());
      expect(field.decoration?.hint, isA<ExcludeSemantics>());
      expect(find.text('Category search'), findsOneWidget);
      expect(find.text('Find a category'), findsOneWidget);
      expect(
        field.decoration?.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
      final selectedNode = tester.getSemantics(
        find.byKey(const ValueKey('buy-category-semantics-all')),
      );
      final selectedLabel = session.categories
          .firstWhere((category) => category.id == session.selectedCategoryId)
          .label;
      expect(
        selectedNode.label,
        startsWith('Shop category, $selectedLabel, selected'),
      );
      expect(selectedNode.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-category-close'))),
        const Size(44, 44),
      );
      semantics.dispose();
    },
  );

  testWidgets('R58.8.8 FIX7 category search exports editable semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final search = find.byKey(const ValueKey('buy-category-search-semantics'));
    expect(search, findsOneWidget);
    var data = tester.getSemantics(search).getSemanticsData();
    expect(data.label, 'Category search');
    expect(data.hint, 'Find a category');
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.hasAction(SemanticsAction.focus), isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.hasAction(SemanticsAction.setText), isTrue);
    expect(data.value, isEmpty);

    await tester.tap(find.byKey(const ValueKey('buy-category-search')));
    await tester.pump();
    data = tester.getSemantics(search).getSemanticsData();
    expect(data.hasAction(SemanticsAction.setText), isTrue);
    expect(data.flagsCollection.isFocused, Tristate.isTrue);
    await tester.enterText(
      find.byKey(const ValueKey('buy-category-search')),
      'shop supplies',
    );
    await tester.pumpAndSettle();
    data = tester.getSemantics(search).getSemanticsData();
    expect(data.label, 'Category search');
    expect(data.hint, 'Find a category');
    expect(data.value, 'shop supplies');
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.flagsCollection.isFocused, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.setText), isTrue);
    semantics.dispose();
  });

  testWidgets('R56.3 honest filtered empty state clears locally', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);
    final initial = session.selectedCategoryId;

    await tester.enterText(
      find.byKey(const ValueKey('buy-category-search')),
      'no such category',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('buy-category-empty')), findsOneWidget);
    expect(find.text('No categories match'), findsOneWidget);
    expect(session.selectedCategoryId, initial);

    await tester.tap(find.byKey(const ValueKey('buy-category-empty-clear')));
    await tester.pump();
    expect(find.byKey(const ValueKey('buy-category-empty')), findsNothing);
    expect(find.byKey(const ValueKey('buy-category-grid')), findsOneWidget);
    expect(session.selectedCategoryId, initial);
  });

  testWidgets('R56.3 FIX2 keeps empty recovery above keyboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    const keyboardInset = 300.0;
    await openSheet(
      tester,
      session,
      viewInsets: const EdgeInsets.only(bottom: keyboardInset),
    );
    final initial = session.selectedCategoryId;

    await tester.enterText(
      find.byKey(const ValueKey('buy-category-search')),
      'nozzcategory',
    );
    await tester.pumpAndSettle();
    final title = find.text('No categories match');
    final clear = find.byKey(const ValueKey('buy-category-empty-clear'));
    final keyboardTop = 800 - keyboardInset;
    expect(title, findsOneWidget);
    expect(clear, findsOneWidget);
    expect(tester.getBottomLeft(title).dy, lessThan(keyboardTop));
    expect(tester.getBottomLeft(clear).dy, lessThanOrEqualTo(keyboardTop));
    expect(tester.getSize(clear).height, greaterThanOrEqualTo(44));

    await tester.tap(clear);
    await tester.pump();
    expect(find.byKey(const ValueKey('buy-category-grid')), findsOneWidget);
    expect(session.selectedCategoryId, initial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R56.3 reduced motion opens and selects without delayed state', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, disableAnimations: true, settle: false);
    final target = session.categories[1];
    expect(find.byKey(const ValueKey('buy-category-sheet-route')), findsOne);

    await tester.tap(find.byKey(ValueKey('buy-category-${target.id}')));
    await tester.pump();
    await tester.pump();
    expect(session.selectedCategoryId, target.id);
    expect(
      find.byKey(const ValueKey('buy-category-sheet-route')),
      findsNothing,
    );
  });

  testWidgets('R56.3 compact 140 percent and keyboard geometry remain usable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(
      tester,
      session,
      textScale: 1.4,
      viewInsets: const EdgeInsets.only(bottom: 260),
    );

    final surface = find.byKey(const ValueKey('buy-category-sheet-surface'));
    expect(tester.getSize(surface).width, lessThanOrEqualTo(320));
    expect(find.byKey(const ValueKey('buy-category-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-category-close')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('buy-category-search')),
      'shop supplies',
    );
    await tester.pumpAndSettle();
    final target = find.byKey(const ValueKey('buy-category-shop-supplies'));
    final label = find.byKey(
      const ValueKey('buy-category-label-shop-supplies'),
    );
    final keyboardTop = 700 - 260;
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
    expect(tester.getBottomLeft(target).dy, lessThanOrEqualTo(keyboardTop));
    expect(tester.getBottomLeft(label).dy, lessThanOrEqualTo(keyboardTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'R58.8.8 filtered category card and label stay wholly above keyboard',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      const keyboardInset = 300.0;
      await openSheet(
        tester,
        session,
        viewInsets: const EdgeInsets.only(bottom: keyboardInset),
      );

      await tester.enterText(
        find.byKey(const ValueKey('buy-category-search')),
        'shop supplies',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-category-sheet-backdrop-blur')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-category-sheet-opaque-content')),
        findsOneWidget,
      );
      final target = find.byKey(const ValueKey('buy-category-shop-supplies'));
      final label = find.byKey(
        const ValueKey('buy-category-label-shop-supplies'),
      );
      const keyboardTop = 800 - keyboardInset;
      expect(target, findsOneWidget);
      expect(label, findsOneWidget);
      expect(tester.getTopLeft(target).dy, greaterThanOrEqualTo(0));
      expect(tester.getBottomLeft(target).dy, lessThanOrEqualTo(keyboardTop));
      expect(tester.getBottomLeft(label).dy, lessThanOrEqualTo(keyboardTop));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('R56.3 category-sheet responsive evidence captures', (
    tester,
  ) async {
    const cases = [
      (
        Size(320, 700),
        1.4,
        false,
        EdgeInsets.zero,
        'compact-320x700-text140',
        false,
      ),
      (Size(360, 800), 1.0, false, EdgeInsets.zero, 'android-360x800', false),
      (Size(390, 844), 1.0, false, EdgeInsets.zero, 'ios-390x844', false),
      (
        Size(390, 844),
        1.0,
        true,
        EdgeInsets.zero,
        'reduced-ios-390x844',
        false,
      ),
      (
        Size(360, 800),
        1.0,
        false,
        EdgeInsets.only(bottom: 300),
        'android-360x800-keyboard-empty',
        true,
      ),
    ];
    for (final capture in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      final session = BuyV2Session(core: BuySession());
      await openSheet(
        tester,
        session,
        disableAnimations: capture.$3,
        textScale: capture.$2,
        viewInsets: capture.$4,
      );
      if (capture.$6) {
        await tester.enterText(
          find.byKey(const ValueKey('buy-category-search')),
          'nozzcategory',
        );
        await tester.pumpAndSettle();
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-v2-r56-3-fix3-category-sheet-${capture.$5}.png',
        ),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);
}
