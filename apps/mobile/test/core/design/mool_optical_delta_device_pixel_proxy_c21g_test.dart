import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

const _labels = ['Shop', 'Wholesale', 'Medicine', 'Orders'];
const _icons = [
  Icons.shopping_bag_outlined,
  Icons.storefront_outlined,
  Icons.local_pharmacy_outlined,
  Icons.receipt_long_outlined,
];

void main() {
  for (final tone in MoolLocalNavigationSurfaceTone.values) {
    testWidgets(
      '${tone.name} rendered pixels materially differ from documented r60.19 flat proxy',
      (tester) async {
        tester.view.physicalSize = const Size(360, 170);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RepaintBoundary(
                      key: ValueKey('c21g-${tone.name}-predecessor'),
                      child: _OpticalBackground(
                        child: _DocumentedR6019FlatProxy(tone: tone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RepaintBoundary(
                      key: ValueKey('c21g-${tone.name}-successor'),
                      child: _OpticalBackground(
                        child: MoolLocalNavigationRail(
                          familyId: tone.name,
                          semanticLabel: '${tone.name} optical delta choices',
                          activeId: 'action-0',
                          surfaceTone: tone,
                          actions: [
                            for (var index = 0; index < 4; index++)
                              MoolLocalNavigationAction(
                                keyName: 'c21g-${tone.name}-$index',
                                id: 'action-$index',
                                label: _labels[index],
                                icon: _icons[index],
                                onPressed: index == 0 ? null : () {},
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final predecessor = await _capture(
          tester,
          ValueKey('c21g-${tone.name}-predecessor'),
        );
        final successor = await _capture(
          tester,
          ValueKey('c21g-${tone.name}-successor'),
        );
        expect(predecessor.length, successor.length);

        var changedPixels = 0;
        var absoluteChannelDelta = 0;
        final pixelCount = predecessor.length ~/ 4;
        for (var offset = 0; offset < predecessor.length; offset += 4) {
          var maximumPixelDelta = 0;
          for (var channel = 0; channel < 3; channel++) {
            final delta =
                (predecessor[offset + channel] - successor[offset + channel])
                    .abs();
            absoluteChannelDelta += delta;
            if (delta > maximumPixelDelta) maximumPixelDelta = delta;
          }
          if (maximumPixelDelta >= 12) changedPixels += 1;
        }
        final changedRatio = changedPixels / pixelCount;
        final meanAbsoluteChannelDelta =
            absoluteChannelDelta / (pixelCount * 3);
        expect(changedRatio, greaterThanOrEqualTo(.08));
        expect(meanAbsoluteChannelDelta, greaterThanOrEqualTo(6));
      },
    );
  }
}

Future<Uint8List> _capture(WidgetTester tester, Key key) async {
  final pixels = await tester.runAsync<Uint8List>(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return pixels!;
}

class _OpticalBackground extends StatelessWidget {
  const _OpticalBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 52,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF8A00), Color(0xFF243B70), Color(0xFFF2E8D7)],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A test-only proxy for the documented C20C/r60.19 flat control contract.
/// It is not a production widget and does not copy the screenbook.
class _DocumentedR6019FlatProxy extends StatelessWidget {
  const _DocumentedR6019FlatProxy({required this.tone});

  final MoolLocalNavigationSurfaceTone tone;

  @override
  Widget build(BuildContext context) {
    final fill = tone == MoolLocalNavigationSurfaceTone.media
        ? const Color(0x94141C2D)
        : const Color(0x85FFFFFF);
    final foreground = MoolLocalNavigationTokens.foreground(tone);
    return Center(
      child: SizedBox(
        width: 304,
        height: 52,
        child: Row(
          children: [
            for (var index = 0; index < 4; index++) ...[
              if (index > 0) const SizedBox(width: 4),
              SizedBox(
                width: 73,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: index == 0
                        ? fill.withValues(alpha: (fill.a + .055).clamp(0, 1))
                        : fill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: foreground.withValues(alpha: .2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_icons[index], size: 20, color: foreground),
                      const SizedBox(height: 1),
                      Text(
                        _labels[index],
                        maxLines: 1,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
