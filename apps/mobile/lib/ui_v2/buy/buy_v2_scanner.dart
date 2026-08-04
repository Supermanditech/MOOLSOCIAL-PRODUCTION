import 'dart:async';

import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final code = (value ?? _controller.text).trim();
    if (code.isNotEmpty) Navigator.of(context).pop(code);
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
      child: ConstrainedBox(
        key: const ValueKey('buy-manual-code-panel'),
        constraints: const BoxConstraints(maxHeight: 238),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      key: const ValueKey('buy-scanner-open-settings'),
                      tooltip: 'Open camera settings',
                      onPressed: () async {
                        await openAppSettings();
                      },
                      icon: const Icon(Icons.settings_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              TextField(
                key: const ValueKey('buy-product-code-field'),
                controller: _controller,
                autofocus: !widget.cameraUnavailable,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Product code',
                  hintText: 'Scan number or product code',
                  prefixIcon: Icon(Icons.barcode_reader),
                ),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: const ValueKey('buy-use-product-code'),
                      onPressed: _submit,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Find product'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

class _BuyV2ProductScannerState extends State<BuyV2ProductScanner> {
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
  bool _handled = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _complete(String code) async {
    if (_handled || code.trim().isEmpty) return;
    _handled = true;
    await _controller.stop();
    if (mounted) Navigator.of(context).pop(code.trim());
  }

  Future<void> _enterCode() async {
    await _controller.stop();
    if (!mounted) return;
    final code = await showBuyV2ManualCodeSheet(context);
    if (!mounted) return;
    if (code != null) {
      await _complete(code);
    } else {
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final frameSize = (size.width * .64).clamp(210.0, 292.0);
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
            errorBuilder: (context, error) => _ScannerCameraError(
              message: error.errorDetails?.message,
              onManual: _enterCode,
            ),
          ),
          Center(
            child: IgnorePointer(
              child: SizedBox(
                width: frameSize,
                height: frameSize,
                child: CustomPaint(painter: const _ScannerFramePainter()),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _ScannerControl(
                        key: const ValueKey('buy-close-scanner'),
                        icon: Icons.close_rounded,
                        label: 'Close scanner',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _ScannerControl(
                        key: const ValueKey('buy-scanner-torch'),
                        icon: Icons.flashlight_on_rounded,
                        label: 'Torch',
                        onTap: _controller.toggleTorch,
                      ),
                      const SizedBox(width: 8),
                      _ScannerControl(
                        key: const ValueKey('buy-scanner-camera'),
                        icon: Icons.cameraswitch_rounded,
                        label: 'Switch camera',
                        onTap: _controller.switchCamera,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 430),
                    padding: const EdgeInsets.fromLTRB(12, 7, 6, 6),
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
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAMERA · BARCODE · QR',
                                style: TextStyle(
                                  color: BuyV2Colors.orange,
                                  fontSize: 9,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Place one code inside the frame',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('buy-scanner-enter-code'),
                          onPressed: _enterCode,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(88, 44),
                            foregroundColor: BuyV2Colors.orange,
                            backgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Enter code'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerControl extends StatelessWidget {
  const _ScannerControl({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: Material(
        color: const Color(0xB8121230),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _ScannerCameraError extends StatelessWidget {
  const _ScannerCameraError({required this.message, required this.onManual});

  final String? message;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF09091D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_rounded,
                color: Colors.white,
                size: 42,
              ),
              const SizedBox(height: 10),
              const Text(
                'Camera could not start',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (message case final detail? when detail.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onManual,
                child: const Text('Enter product code'),
              ),
            ],
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
