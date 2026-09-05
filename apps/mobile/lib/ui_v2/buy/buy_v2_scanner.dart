import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'buy_v2_design.dart';
import 'buy_v2_manual_code_sheet_motion.dart';

typedef BuyV2ScannerLauncher = Future<String?> Function(BuildContext context);

Future<String?> showBuyV2ProductScanner(BuildContext context) async {
  final permission = await Permission.camera.request();
  if (!permission.isGranted) {
    if (!context.mounted) return null;
    return showBuyV2ManualCodeSheet(
      context,
      cameraUnavailable: true,
      canOpenSettings:
          permission.isPermanentlyDenied || permission.isRestricted,
    );
  }
  if (!context.mounted) return null;

  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (_) => const BuyV2ProductScanner(),
    ),
  );
}

Future<String?> showBuyV2ManualCodeSheet(
  BuildContext context, {
  bool cameraUnavailable = false,
  bool canOpenSettings = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    sheetAnimationStyle: BuyV2ManualCodeSheetMotion.resolve(context),
    builder: (sheetContext) => AnimatedPadding(
      duration: BuyV2ManualCodeSheetMotion.resolveKeyboardInsetDuration(
        sheetContext,
      ),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _BuyV2ManualCodePanel(
        cameraUnavailable: cameraUnavailable,
        canOpenSettings: canOpenSettings,
      ),
    ),
  );
}

class _BuyV2ManualCodePanel extends StatefulWidget {
  const _BuyV2ManualCodePanel({
    required this.cameraUnavailable,
    required this.canOpenSettings,
  });

  final bool cameraUnavailable;
  final bool canOpenSettings;

  @override
  State<_BuyV2ManualCodePanel> createState() => _BuyV2ManualCodePanelState();
}

class _BuyV2ManualCodePanelState extends State<_BuyV2ManualCodePanel> {
  final TextEditingController _controller = TextEditingController();
  bool _showCodeError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final code = (value ?? _controller.text).trim();
    if (code.isEmpty) {
      setState(() => _showCodeError = true);
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.cameraUnavailable
        ? 'Camera access needed'
        : 'Enter product code';
    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '$title form',
      child: SafeArea(
        top: false,
        bottom: MediaQuery.viewInsetsOf(context).bottom == 0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final height =
                (238 +
                        (scale - 1).clamp(0, 3) * 100 +
                        (_showCodeError ? 32 : 0))
                    .clamp(0.0, constraints.maxHeight)
                    .toDouble();
            final stackActions = scale > 1.6 || constraints.maxWidth < 280;
            final compactEntry =
                !widget.cameraUnavailable &&
                MediaQuery.viewInsetsOf(context).bottom > 0 &&
                constraints.maxHeight < 300 &&
                scale > 1.6;
            final cancel = Semantics(
              key: const ValueKey('buy-cancel-product-code-semantics'),
              container: true,
              button: true,
              enabled: true,
              label: 'Cancel',
              excludeSemantics: true,
              onTap: () => Navigator.of(context).pop(),
              child: TextButton(
                key: const ValueKey('buy-cancel-product-code'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', textAlign: TextAlign.center),
              ),
            );
            final submit = Semantics(
              key: const ValueKey('buy-use-product-code-semantics'),
              container: true,
              button: true,
              enabled: true,
              label: 'Find product',
              excludeSemantics: true,
              onTap: _submit,
              child: FilledButton.icon(
                key: const ValueKey('buy-use-product-code'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Find product', textAlign: TextAlign.center),
              ),
            );
            return SizedBox(
              key: const ValueKey('buy-manual-code-panel'),
              height: height,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!compactEntry) ...[
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: BuyV2Colors.softOrange,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: BuyV2Colors.orange,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            color: BuyV2Colors.ink,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          widget.cameraUnavailable
                                              ? 'Use a code now, or allow camera access in settings.'
                                              : 'Barcode, QR or catalogue code',
                                          style: const TextStyle(
                                            color: BuyV2Colors.muted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (widget.canOpenSettings)
                                    IconButton(
                                      key: const ValueKey(
                                        'buy-scanner-open-settings',
                                      ),
                                      tooltip: 'Open camera settings',
                                      onPressed: () async {
                                        await openAppSettings();
                                      },
                                      icon: const Icon(Icons.settings_rounded),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 7),
                            ],
                            if (compactEntry) const SizedBox(height: 12),
                            TextField(
                              key: const ValueKey('buy-product-code-field'),
                              controller: _controller,
                              autofocus: !widget.cameraUnavailable,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Product code',
                                hintText: 'Scan number or product code',
                                errorText: _showCodeError
                                    ? 'Enter a product code'
                                    : null,
                                errorMaxLines: 2,
                                prefixIcon: const Icon(Icons.barcode_reader),
                              ),
                              onChanged: (_) {
                                if (_showCodeError) {
                                  setState(() => _showCodeError = false);
                                }
                              },
                              onSubmitted: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (stackActions)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [submit, const SizedBox(height: 6), cancel],
                      )
                    else
                      Row(
                        children: [
                          Expanded(child: cancel),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: submit),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BuyV2ProductScanner extends StatefulWidget {
  const BuyV2ProductScanner({super.key});

  @override
  State<BuyV2ProductScanner> createState() => _BuyV2ProductScannerState();
}

class _BuyV2ProductScannerState extends State<BuyV2ProductScanner>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
    ],
  );
  late final AnimationController _scanLineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: .5,
  );
  Timer? _scanFeedbackTimer;
  bool _handled = false;
  bool _scanActionBusy = false;
  bool _manualOpen = false;
  bool? _motionEnabled;
  String? _scanStatus;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncScanMotion);
  }

  void _syncScanMotion() {
    if (!mounted) return;
    final active = _controller.value.isRunning && !_handled && !_manualOpen;
    if (_motionEnabled == true && active) {
      if (!_scanLineController.isAnimating) {
        unawaited(_scanLineController.repeat(reverse: true));
      }
    } else {
      _scanLineController
        ..stop()
        ..value = .5;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motionEnabled = !MediaQuery.disableAnimationsOf(context);
    if (_motionEnabled == motionEnabled) return;
    _motionEnabled = motionEnabled;
    _syncScanMotion();
  }

  @override
  void dispose() {
    _scanFeedbackTimer?.cancel();
    _controller.removeListener(_syncScanMotion);
    _scanLineController.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _complete(String code) async {
    if (_handled || code.trim().isEmpty) return;
    _handled = true;
    _scanFeedbackTimer?.cancel();
    if (mounted) {
      setState(() {
        _scanActionBusy = false;
        _scanStatus = 'Code found';
      });
    }
    unawaited(HapticFeedback.mediumImpact());
    try {
      await _controller.stop();
    } on Object {
      // A decoded/manual result must not be lost if camera teardown fails.
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) Navigator.of(context).pop(code.trim());
  }

  Future<void> _scanNow() async {
    if (_handled ||
        _scanActionBusy ||
        _manualOpen ||
        _controller.value.isStarting) {
      return;
    }
    _scanFeedbackTimer?.cancel();
    setState(() {
      _scanActionBusy = true;
      _scanStatus = null;
    });
    unawaited(HapticFeedback.selectionClick());
    try {
      final direction = _controller.value.cameraDirection;
      await _controller.stop();
      if (!mounted || _handled || _manualOpen) return;
      await _controller.start(
        cameraDirection: direction == CameraFacing.unknown ? null : direction,
      );
    } on Object {
      if (!mounted || _handled) return;
      setState(() {
        _scanActionBusy = false;
        _scanStatus = 'Camera could not restart. Enter the code instead.';
      });
      return;
    }
    if (!mounted || _handled || _manualOpen) return;
    if (!_controller.value.isRunning) {
      setState(() {
        _scanActionBusy = false;
        _scanStatus = 'Camera could not start. Enter the code instead.';
      });
      return;
    }
    setState(() => _scanStatus = 'Scanning now — hold the code steady');
    _scanFeedbackTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted || _handled) return;
      setState(() {
        _scanActionBusy = false;
        _scanStatus = 'Still scanning — move closer or enter the code';
      });
    });
  }

  Future<void> _enterCode() async {
    if (_handled || _manualOpen || _scanActionBusy) return;
    _scanFeedbackTimer?.cancel();
    final direction = _controller.value.cameraDirection;
    setState(() {
      _manualOpen = true;
      _scanStatus = null;
    });
    _syncScanMotion();
    try {
      await _controller.stop();
    } on Object {
      // Manual entry remains available even when the camera cannot stop cleanly.
    }
    if (!mounted) return;
    final code = await showBuyV2ManualCodeSheet(context);
    if (!mounted) return;
    setState(() => _manualOpen = false);
    if (code != null) {
      await _complete(code);
    } else {
      try {
        await _controller.start(
          cameraDirection: direction == CameraFacing.unknown ? null : direction,
        );
        if (mounted && !_controller.value.isRunning) {
          setState(
            () =>
                _scanStatus = 'Camera could not start. Enter the code instead.',
          );
        }
      } on Object {
        if (mounted) {
          setState(
            () =>
                _scanStatus = 'Camera could not start. Enter the code instead.',
          );
        }
      }
    }
  }

  Future<void> _changeCameraControl({required bool torch}) async {
    if (_handled ||
        _scanActionBusy ||
        _manualOpen ||
        !_controller.value.isRunning) {
      return;
    }
    final previous = _controller.value;
    _scanFeedbackTimer?.cancel();
    setState(() {
      _scanActionBusy = true;
      _scanStatus = null;
    });
    try {
      if (torch) {
        await _controller.toggleTorch();
      } else {
        await _controller.switchCamera();
      }
      if (!mounted || _handled) return;
      if (!torch &&
          _controller.value.cameraDirection == previous.cameraDirection) {
        _scanStatus = 'Another camera is not available';
      }
    } on Object {
      if (!mounted || _handled) return;
      _scanStatus = torch
          ? 'Torch could not change. Try again.'
          : 'Camera could not switch. Try again or enter the code.';
    } finally {
      if (mounted && !_handled) setState(() => _scanActionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('buy-product-scanner'),
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            tapToFocus: true,
            onDetect: (capture) {
              if (_manualOpen) return;
              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue?.trim();
                if (value != null && value.isNotEmpty) {
                  unawaited(_complete(value));
                  break;
                }
              }
            },
            placeholderBuilder: (context) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorBuilder: (context, error) =>
                const ColoredBox(color: Color(0xFF09091D)),
          ),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, camera, _) => _ScannerOverlay(
              camera: camera,
              feedback: _scanStatus,
              busy: _scanActionBusy || camera.isStarting || _handled,
              manualOpen: _manualOpen,
              scanLine: _scanLineController,
              onClose: () => Navigator.of(context).pop(),
              onTorch: () => _changeCameraControl(torch: true),
              onCamera: () => _changeCameraControl(torch: false),
              onScanNow: _scanNow,
              onEnterCode: _enterCode,
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
Widget buildBuyV2ScannerOverlayForTesting({
  required MobileScannerState camera,
  String? feedback,
  bool busy = false,
  bool manualOpen = false,
  Animation<double> scanLine = const AlwaysStoppedAnimation(.5),
  required VoidCallback onClose,
  required Future<void> Function() onTorch,
  required Future<void> Function() onCamera,
  required Future<void> Function() onScanNow,
  required Future<void> Function() onEnterCode,
}) => _ScannerOverlay(
  camera: camera,
  feedback: feedback,
  busy: busy,
  manualOpen: manualOpen,
  scanLine: scanLine,
  onClose: onClose,
  onTorch: onTorch,
  onCamera: onCamera,
  onScanNow: onScanNow,
  onEnterCode: onEnterCode,
);

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({
    required this.camera,
    required this.feedback,
    required this.busy,
    required this.manualOpen,
    required this.scanLine,
    required this.onClose,
    required this.onTorch,
    required this.onCamera,
    required this.onScanNow,
    required this.onEnterCode,
  });

  final MobileScannerState camera;
  final String? feedback;
  final bool busy;
  final bool manualOpen;
  final Animation<double> scanLine;
  final VoidCallback onClose;
  final Future<void> Function() onTorch;
  final Future<void> Function() onCamera;
  final Future<void> Function() onScanNow;
  final Future<void> Function() onEnterCode;

  @override
  Widget build(BuildContext context) {
    final active = camera.isRunning && !manualOpen && camera.error == null;
    final status = manualOpen
        ? 'Scanning paused while you enter a code'
        : feedback == 'Code found'
        ? feedback!
        : camera.error != null
        ? 'Camera unavailable. Try Scan now or enter the code.'
        : camera.isStarting || !camera.isInitialized
        ? 'Starting camera…'
        : !active
        ? 'Camera paused. Tap Scan now to resume.'
        : feedback ?? 'Automatic scanning is active';
    final torchAvailable =
        active && camera.torchState != TorchState.unavailable;
    final torchOn = camera.torchState == TorchState.on;
    final torchAutomatic = camera.torchState == TorchState.auto;
    final canSwitch =
        active &&
        (camera.availableCameras == null || camera.availableCameras! > 1) &&
        (camera.cameraDirection == CameraFacing.front ||
            camera.cameraDirection == CameraFacing.back);
    final actions = SingleChildScrollView(
      child: _ScannerActionPanel(
        status: status,
        scanning: busy && active,
        busy: busy || manualOpen || camera.isStarting,
        onScanNow: onScanNow,
        onEnterCode: onEnterCode,
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Row(
                children: [
                  _ScannerControl(
                    key: const ValueKey('buy-close-scanner'),
                    icon: Icons.close_rounded,
                    label: 'Close scanner',
                    onTap: onClose,
                  ),
                  const Spacer(),
                  _ScannerControl(
                    key: const ValueKey('buy-scanner-torch'),
                    icon: torchAutomatic
                        ? Icons.flash_auto_rounded
                        : torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    label: !torchAvailable
                        ? 'Torch unavailable on this camera'
                        : torchAutomatic
                        ? 'Torch automatic'
                        : torchOn
                        ? 'Torch on'
                        : 'Torch off',
                    toggled: torchAvailable && !torchAutomatic ? torchOn : null,
                    onTap: torchAvailable && !busy ? () => onTorch() : null,
                  ),
                  const SizedBox(width: 8),
                  _ScannerControl(
                    key: const ValueKey('buy-scanner-camera'),
                    icon: Icons.cameraswitch_rounded,
                    label: !canSwitch
                        ? 'Another camera is not available'
                        : camera.cameraDirection == CameraFacing.front
                        ? 'Switch to rear camera'
                        : 'Switch to front camera',
                    onTap: canSwitch && !busy ? () => onCamera() : null,
                  ),
                ],
              ),
              Expanded(
                child: constraints.maxWidth > constraints.maxHeight
                    ? Row(
                        children: [
                          Expanded(
                            child: _ScannerFrame(
                              active: active,
                              scanLine: scanLine,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: actions),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _ScannerFrame(
                              active: active,
                              scanLine: scanLine,
                            ),
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * .65,
                            ),
                            child: actions,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.active, required this.scanLine});
  final bool active;
  final Animation<double> scanLine;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = (constraints.maxWidth * .64)
          .clamp(0.0, 292.0)
          .clamp(0.0, (constraints.maxHeight - 24).clamp(0.0, double.infinity))
          .toDouble();
      return Center(
        child: IgnorePointer(
          child: SizedBox.square(
            key: const ValueKey('buy-scanner-frame'),
            dimension: side,
            child: Stack(
              children: [
                if (side > 48)
                  const Positioned.fill(
                    child: CustomPaint(painter: _ScannerFramePainter()),
                  ),
                if (active && side > 48)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: scanLine,
                      builder: (context, _) => Align(
                        alignment: Alignment(0, (scanLine.value * 1.55) - .775),
                        child: Container(
                          key: const ValueKey('buy-scanner-active-line'),
                          height: 2.5,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: BuyV2Colors.royal,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x990A65FF),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

@visibleForTesting
Widget buildBuyV2ScannerActionPanelForTesting({
  required String status,
  required bool scanning,
  required Future<void> Function() onScanNow,
  required Future<void> Function() onEnterCode,
}) => _ScannerActionPanel(
  status: status,
  scanning: scanning,
  onScanNow: onScanNow,
  onEnterCode: onEnterCode,
);

class _ScannerActionPanel extends StatelessWidget {
  const _ScannerActionPanel({
    required this.status,
    required this.scanning,
    this.busy = false,
    required this.onScanNow,
    required this.onEnterCode,
  });

  final String status;
  final bool scanning;
  final bool busy;
  final Future<void> Function() onScanNow;
  final Future<void> Function() onEnterCode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackActions =
            constraints.maxWidth.clamp(0, 430) < 320 ||
            MediaQuery.textScalerOf(context).scale(12) > 20;
        final scanAction = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: FilledButton.icon(
            key: const ValueKey('buy-scanner-scan-now'),
            onPressed: scanning || busy ? null : () => onScanNow(),
            style: FilledButton.styleFrom(
              backgroundColor: BuyV2Colors.royal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: BuyV2Colors.royal,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: scanning
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.center_focus_strong_rounded, size: 18),
            label: Text(
              scanning ? 'Scanning…' : 'Scan now',
              textAlign: TextAlign.center,
            ),
          ),
        );
        final manualAction = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: OutlinedButton(
            key: const ValueKey('buy-scanner-enter-code'),
            onPressed: busy ? null : () => onEnterCode(),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFF121230),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF121230),
              disabledForegroundColor: Colors.white60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              side: const BorderSide(color: Colors.white70),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Enter code', textAlign: TextAlign.center),
          ),
        );
        return Semantics(
          key: const ValueKey('buy-scanner-active-status'),
          liveRegion: true,
          label: status,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xE6121230),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'BARCODE · QR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Place one code inside the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      width: scanning ? 9 : 7,
                      height: scanning ? 9 : 7,
                      decoration: BoxDecoration(
                        color: scanning ? BuyV2Colors.royal : Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Text(
                          status,
                          key: ValueKey(status),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (stackActions) ...[
                  scanAction,
                  const SizedBox(height: 7),
                  manualAction,
                ] else
                  Row(
                    children: [
                      Expanded(flex: 2, child: scanAction),
                      const SizedBox(width: 8),
                      Expanded(child: manualAction),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScannerControl extends StatelessWidget {
  const _ScannerControl({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.toggled,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool? toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      toggled: toggled,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Material(
          color: toggled == true ? BuyV2Colors.royal : const Color(0xB8121230),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                color: onTap == null ? Colors.white54 : Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  const _ScannerFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const length = 34.0;
    final glow = Paint()
      ..color = const Color(0x6600E6C7)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..shader = const LinearGradient(
        colors: [BuyV2Colors.orange, Color(0xFF00E6C7)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final paint in [glow, line]) {
      final path = Path()
        ..moveTo(0, length)
        ..lineTo(0, 0)
        ..lineTo(length, 0)
        ..moveTo(size.width - length, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, length)
        ..moveTo(size.width, size.height - length)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - length, size.height)
        ..moveTo(length, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - length);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
