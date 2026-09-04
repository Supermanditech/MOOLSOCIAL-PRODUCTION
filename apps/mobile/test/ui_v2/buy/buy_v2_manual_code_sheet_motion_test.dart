import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_manual_code_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app({
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool cameraUnavailable = false,
    bool canOpenSettings = false,
    ValueChanged<String?>? onResult,
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const ValueKey('open-manual-code-sheet'),
              onPressed: () async {
                final result = await showBuyV2ManualCodeSheet(
                  context,
                  cameraUnavailable: cameraUnavailable,
                  canOpenSettings: canOpenSettings,
                );
                onResult?.call(result);
              },
              child: const Text('Open manual code'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool cameraUnavailable = false,
    bool canOpenSettings = false,
    ValueChanged<String?>? onResult,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(
        disableAnimations: disableAnimations,
        textScale: textScale,
        viewInsets: viewInsets,
        cameraUnavailable: cameraUnavailable,
        canOpenSettings: canOpenSettings,
        onResult: onResult,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-manual-code-sheet')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('R56.2 owns bounded route and keyboard-inset motion', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    late Duration normalInset;
    late Duration reducedInset;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2ManualCodeSheetMotion.resolve(context);
                  normalInset =
                      BuyV2ManualCodeSheetMotion.resolveKeyboardInsetDuration(
                        context,
                      );
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2ManualCodeSheetMotion.resolve(context);
                  reducedInset =
                      BuyV2ManualCodeSheetMotion.resolveKeyboardInsetDuration(
                        context,
                      );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, BuyV2ManualCodeSheetMotion.forwardDuration);
    expect(normal.reverseDuration, BuyV2ManualCodeSheetMotion.reverseDuration);
    expect(normal.curve, Curves.easeOutBack);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(normalInset, const Duration(milliseconds: 180));
    expect(normal.reverseDuration, lessThan(normal.duration!));
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
    expect(reducedInset, Duration.zero);
  });

  testWidgets(
    'R56.2 arrival is finite and Back clears focus without a result',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? result = 'unchanged';
      await openSheet(
        tester,
        onResult: (value) => result = value,
        settle: false,
      );
      final panel = find.byKey(const ValueKey('buy-manual-code-panel'));
      expect(panel, findsOneWidget);

      await tester.pump(const Duration(milliseconds: 140));
      final midTop = tester.getTopLeft(panel).dy;
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();
      final settledTop = tester.getTopLeft(panel).dy;
      expect(midTop, lessThan(settledTop));
      expect(settledTop - midTop, lessThan(22));
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 219));
      expect(panel, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(result, isNull);
    },
  );

  testWidgets(
    'R56.2 reduced motion is immediate and camera recovery does not autofocus',
    (tester) async {
      String? result = 'unchanged';
      await openSheet(
        tester,
        disableAnimations: true,
        cameraUnavailable: true,
        canOpenSettings: true,
        onResult: (value) => result = value,
        settle: false,
      );
      final panel = find.byKey(const ValueKey('buy-manual-code-panel'));
      final immediateTop = tester.getTopLeft(panel).dy;
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(panel).dy, immediateTop);
      expect(find.text('Camera access needed'), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-scanner-open-settings')), findsOne);
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(result, isNull);
    },
  );

  testWidgets(
    'R56.2 compact large-text keyboard form keeps honest result ownership',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      String? result;
      await openSheet(
        tester,
        textScale: 1.4,
        viewInsets: const EdgeInsets.only(bottom: 260),
        onResult: (value) => result = value,
      );

      final panel = find.byKey(const ValueKey('buy-manual-code-panel'));
      expect(tester.getSize(panel).height, lessThanOrEqualTo(238));
      expect(find.bySemanticsLabel('Enter product code form'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Product code')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-product-code-field')), findsOne);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Find product'), findsOneWidget);
      for (final key in const [
        ValueKey('buy-cancel-product-code'),
        ValueKey('buy-use-product-code'),
      ]) {
        final action = find.byKey(key);
        expect(tester.getSize(action).height, 44);
        expect(
          tester.getRect(action).bottom,
          lessThanOrEqualTo(tester.getRect(panel).bottom),
        );
      }
      for (final key in const [
        ValueKey('buy-cancel-product-code-semantics'),
        ValueKey('buy-use-product-code-semantics'),
      ]) {
        final semanticsNode = tester.getSemantics(find.byKey(key));
        expect(semanticsNode.rect.width, greaterThan(0));
        expect(semanticsNode.rect.height, 44);
      }
      expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
      expect(find.bySemanticsLabel('Find product'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('buy-use-product-code')));
      await tester.pumpAndSettle();
      expect(panel, findsOneWidget);
      expect(result, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('buy-product-code-field')),
        '  m-paracetamol-500  ',
      );
      await tester.tap(find.byKey(const ValueKey('buy-use-product-code')));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(result, 'm-paracetamol-500');
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('scanner action panel makes automatic and requested scan clear', (
    tester,
  ) async {
    var scanCalls = 0;
    var manualCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: buildBuyV2ScannerActionPanelForTesting(
              status: 'Automatic scanning is active',
              scanning: false,
              onScanNow: () async {
                scanCalls += 1;
              },
              onEnterCode: () async {
                manualCalls += 1;
              },
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('buy-scanner-active-status')),
      findsOneWidget,
    );
    expect(find.text('Automatic scanning is active'), findsOneWidget);
    expect(find.text('Scan now'), findsOneWidget);
    expect(find.text('Enter code'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-scanner-scan-now')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-scanner-enter-code')));
    await tester.pump();
    expect(scanCalls, 1);
    expect(manualCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scanner action panel fits compact large text while scanning', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.4),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: buildBuyV2ScannerActionPanelForTesting(
              status: 'Scanning now — hold the code steady',
              scanning: true,
              onScanNow: () async {},
              onEnterCode: () async {},
            ),
          ),
        ),
      ),
    );

    final panel = find.byKey(const ValueKey('buy-scanner-active-status'));
    final scanButton = tester.widget<FilledButton>(
      find.descendant(of: panel, matching: find.byType(FilledButton)),
    );
    expect(find.text('Scanning…'), findsOneWidget);
    expect(find.text('Scanning now — hold the code steady'), findsOneWidget);
    expect(scanButton.onPressed, isNull);
    expect(tester.getSize(panel).width, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('R56.2 scanner manual-code responsive evidence captures', (
    tester,
  ) async {
    const cases = [
      (Size(320, 700), 1.4, false, EdgeInsets.zero, 'compact-320x700-text140'),
      (Size(360, 800), 1.0, false, EdgeInsets.zero, 'android-360x800'),
      (Size(390, 844), 1.0, false, EdgeInsets.zero, 'ios-390x844'),
      (Size(390, 844), 1.0, true, EdgeInsets.zero, 'reduced-ios-390x844'),
      (
        Size(360, 800),
        1.0,
        false,
        EdgeInsets.only(bottom: 300),
        'android-360x800-keyboard',
      ),
    ];
    for (final capture in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      await openSheet(
        tester,
        disableAnimations: capture.$3,
        textScale: capture.$2,
        viewInsets: capture.$4,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-v2-r56-2-fix2-manual-code-${capture.$5}.png',
        ),
      );
    }
    tester.view.reset();
  }, skip: true);
}
