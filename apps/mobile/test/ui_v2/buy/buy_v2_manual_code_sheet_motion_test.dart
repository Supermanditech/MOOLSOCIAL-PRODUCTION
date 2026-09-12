import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_manual_code_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> capture(WidgetTester tester, String label) async {
    if (!const bool.fromEnvironment('BUY_R66_SCANNER_CAPTURE')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('buy-scanner-review-capture')),
    );
    await tester.runAsync(() async {
      // Fixed package build output only: no caller-controlled external path.
      final directory = Directory('build/r66-scanner-review-v3-20260905');
      await directory.create(recursive: true);
      final output = File('${directory.path}/$label.png');
      if (await output.exists()) {
        throw StateError('Review image already exists');
      }
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Review image encoding failed');
        await output.writeAsBytes(data.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  Widget app({
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    EdgeInsets viewPadding = EdgeInsets.zero,
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
            padding: viewPadding,
            viewPadding: viewPadding,
          ),
          child: RepaintBoundary(
            key: const ValueKey('buy-scanner-review-capture'),
            child: child!,
          ),
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
    EdgeInsets viewPadding = EdgeInsets.zero,
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
        viewPadding: viewPadding,
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
      expect(tester.getRect(panel).top, greaterThanOrEqualTo(0));
      expect(tester.getRect(panel).bottom, lessThanOrEqualTo(440));
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
        expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
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
        expect(semanticsNode.rect.height, greaterThanOrEqualTo(44));
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

  testWidgets('R66 empty manual code provides correction without navigation', (
    tester,
  ) async {
    String? result;
    await openSheet(tester, onResult: (value) => result = value);
    final field = find.byKey(const ValueKey('buy-product-code-field'));
    await tester.enterText(field, '   ');
    await tester.tap(find.byKey(const ValueKey('buy-use-product-code')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a product code'), findsOneWidget);
    expect(result, isNull);
    expect(find.byKey(const ValueKey('buy-manual-code-panel')), findsOneWidget);
    await tester.enterText(field, '  R66-BARCODE-123  ');
    await tester.pumpAndSettle();
    expect(find.text('Enter a product code'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(result, 'R66-BARCODE-123');
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(320, 568), Size(360, 800)]) {
    testWidgets('R66 manual actions fit keyboard and 200% text at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? result = 'unchanged';
      await openSheet(
        tester,
        textScale: 2,
        viewInsets: const EdgeInsets.only(bottom: 240),
        viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
        onResult: (value) => result = value,
      );
      await capture(
        tester,
        'manual-${size.width.toInt()}x${size.height.toInt()}-text200-keyboard',
      );
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      if (size.height < 600) {
        expect(find.text('Enter product code'), findsNothing);
        expect(find.text('Barcode, QR or catalogue code'), findsNothing);
      }
      expect(
        tester.getTopLeft(find.text('Product code')).dy,
        greaterThanOrEqualTo(viewport.top),
      );
      expect(
        tester.getBottomRight(find.byType(EditableText)).dy,
        lessThanOrEqualTo(viewport.bottom),
      );
      for (final (key, label) in const [
        ('buy-cancel-product-code', 'Cancel'),
        ('buy-use-product-code', 'Find product'),
      ]) {
        final action = find.byKey(ValueKey(key));
        final bounds = tester.getRect(action);
        final labelBounds = tester.getRect(find.text(label));
        expect(bounds.bottom, lessThanOrEqualTo(size.height - 240));
        expect(bounds.top, greaterThanOrEqualTo(24));
        expect(bounds.height, greaterThanOrEqualTo(44));
        expect(labelBounds.top, greaterThanOrEqualTo(bounds.top + 8));
        expect(labelBounds.bottom, lessThanOrEqualTo(bounds.bottom - 8));
        expect(action.hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('buy-cancel-product-code')));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  }

  testWidgets(
    'R66 manual actions remain above Android navigation without IME',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await openSheet(
        tester,
        cameraUnavailable: true,
        viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
      );
      for (final key in ['buy-cancel-product-code', 'buy-use-product-code']) {
        final bounds = tester.getRect(find.byKey(ValueKey(key)));
        expect(bounds.bottom, lessThanOrEqualTo(752));
      }
      expect(tester.takeException(), isNull);
    },
  );

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

  MobileScannerState runningCamera({
    TorchState torch = TorchState.off,
    CameraFacing facing = CameraFacing.back,
    int count = 2,
  }) => const MobileScannerState.uninitialized().copyWith(
    isInitialized: true,
    isRunning: true,
    cameraDirection: facing,
    availableCameras: count,
    torchState: torch,
    size: const Size(720, 1600),
  );

  Widget scannerApp({
    required MobileScannerState camera,
    double textScale = 1,
    bool reduced = false,
    String? feedback,
    bool manualOpen = false,
    Future<void> Function()? onTorch,
    Future<void> Function()? onCamera,
    Future<void> Function()? onManual,
  }) => MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduced,
        padding: const EdgeInsets.only(top: 24, bottom: 48),
        viewPadding: const EdgeInsets.only(top: 24, bottom: 48),
      ),
      child: RepaintBoundary(
        key: const ValueKey('buy-scanner-review-capture'),
        child: child!,
      ),
    ),
    home: Scaffold(
      backgroundColor: Colors.black,
      body: buildBuyV2ScannerOverlayForTesting(
        camera: camera,
        feedback: feedback,
        manualOpen: manualOpen,
        onClose: () {},
        onTorch: onTorch ?? () async {},
        onCamera: onCamera ?? () async {},
        onScanNow: () async {},
        onEnterCode: onManual ?? () async {},
      ),
    ),
  );

  for (final (size, scale) in const [
    (Size(360, 800), 1.0),
    (Size(320, 568), 2.0),
    (Size(430, 932), 2.0),
    (Size(800, 360), 1.4),
  ]) {
    testWidgets('R66 scanner frame and controls do not overlap $size/$scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        scannerApp(camera: runningCamera(), textScale: scale, reduced: true),
      );
      await tester.pumpAndSettle();
      await capture(
        tester,
        'scanner-${size.width.toInt()}x${size.height.toInt()}-text$scale',
      );
      final frame = tester.getRect(
        find.byKey(const ValueKey('buy-scanner-frame')),
      );
      final panel = tester.getRect(
        find.byKey(const ValueKey('buy-scanner-active-status')),
      );
      expect(frame.overlaps(panel), isFalse);
      expect(frame.shortestSide, greaterThanOrEqualTo(80));
      expect(
        frame.top,
        greaterThanOrEqualTo(
          tester
              .getRect(find.byKey(const ValueKey('buy-close-scanner')))
              .bottom,
        ),
      );
      for (final (key, label) in const [
        ('buy-scanner-scan-now', 'Scan now'),
        ('buy-scanner-enter-code', 'Enter code'),
      ]) {
        final action = find.byKey(ValueKey(key));
        expect(action.hitTestable(), findsOneWidget);
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        final bounds = tester.getRect(action);
        final text = tester.getRect(find.text(label));
        expect(bounds.bottom, lessThanOrEqualTo(size.height - 48));
        expect(bounds.height, greaterThanOrEqualTo(44));
        expect(text.top, greaterThanOrEqualTo(bounds.top + 8));
        expect(text.bottom, lessThanOrEqualTo(bounds.bottom - 8));
        expect(action.hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('R66 scanner manual action uses opaque contrasting colours', (
    tester,
  ) async {
    await tester.pumpWidget(scannerApp(camera: runningCamera()));
    final button = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('buy-scanner-enter-code')),
    );
    final background = button.style!.backgroundColor!.resolve({})!;
    final foreground = button.style!.foregroundColor!.resolve({})!;
    expect(background.a, 1);
    expect(
      (foreground.computeLuminance() + .05) /
          (background.computeLuminance() + .05),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('R66 scanner exposes live camera capabilities without guessing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var torchCalls = 0;
      var cameraCalls = 0;
      await tester.pumpWidget(
        scannerApp(
          camera: runningCamera(),
          onTorch: () async {
            torchCalls++;
          },
          onCamera: () async {
            cameraCalls++;
          },
        ),
      );
      expect(find.bySemanticsLabel('Torch off'), findsOneWidget);
      expect(find.bySemanticsLabel('Switch to front camera'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-scanner-torch')));
      await tester.tap(find.byKey(const ValueKey('buy-scanner-camera')));
      expect(torchCalls, 1);
      expect(cameraCalls, 1);
      // UI follows a provider state update, not a speculative local toggle.
      expect(find.bySemanticsLabel('Torch off'), findsOneWidget);
      await tester.pumpWidget(
        scannerApp(camera: runningCamera(torch: TorchState.on)),
      );
      expect(find.bySemanticsLabel('Torch on'), findsOneWidget);
      await tester.pumpWidget(
        scannerApp(camera: runningCamera(torch: TorchState.auto)),
      );
      expect(find.bySemanticsLabel('Torch automatic'), findsOneWidget);
      await tester.pumpWidget(
        scannerApp(
          camera: runningCamera(
            torch: TorchState.unavailable,
            facing: CameraFacing.front,
            count: 1,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel('Torch unavailable on this camera'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Another camera is not available'),
        findsOneWidget,
      );
      for (final key in ['buy-scanner-torch', 'buy-scanner-camera']) {
        final ink = tester.widget<InkWell>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(InkWell),
          ),
        );
        expect(ink.onTap, isNull);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('R66 active scanning is claimed only for a running camera', (
    tester,
  ) async {
    await tester.pumpWidget(
      scannerApp(camera: const MobileScannerState.uninitialized()),
    );
    expect(find.text('Starting camera…'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-scanner-active-line')), findsNothing);
    await tester.pumpWidget(scannerApp(camera: runningCamera()));
    await tester.pumpAndSettle();
    expect(find.text('Automatic scanning is active'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-scanner-active-line')),
      findsOneWidget,
    );
    await tester.pumpWidget(
      scannerApp(
        camera: runningCamera().copyWith(isRunning: false),
        feedback: 'Still scanning — move closer or enter the code',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Camera paused. Tap Scan now to resume.'), findsOneWidget);
    expect(
      find.text('Still scanning — move closer or enter the code'),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-scanner-active-line')), findsNothing);
    await tester.pumpWidget(
      scannerApp(camera: runningCamera(), manualOpen: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Scanning paused while you enter a code'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-scanner-active-line')), findsNothing);
    await tester.pumpWidget(
      scannerApp(
        camera: runningCamera().copyWith(
          isRunning: false,
          error: MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
            errorDetails: MobileScannerErrorDetails(
              message: 'INTERNAL_CAMERA_DIAGNOSTIC',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Camera unavailable. Try Scan now or enter the code.'),
      findsOneWidget,
    );
    expect(find.textContaining('INTERNAL_CAMERA_DIAGNOSTIC'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('buy-scanner-enter-code')),
          )
          .onPressed,
      isNotNull,
    );
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
