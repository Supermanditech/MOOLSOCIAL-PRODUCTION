import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

const _destinationPixel = Color(0xFF246080);

const _families = <(String, int)>[
  ('social', 4),
  ('buy', 4),
  ('eat', 2),
  ('ride', 3),
  ('book', 2),
  ('work', 2),
];

void main() {
  for (final family in _families) {
    testWidgets(
      'C22D ${family.$1} overlays capsules without a full-width strap',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        MoolDestinationNavigationV2.debugResetDisclosureSession();

        final taps = <String>[];
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('c22d-root'),
            child: MaterialApp(
              home: Scaffold(
                extendBody: true,
                body: const SizedBox.expand(
                  child: ColoredBox(color: _destinationPixel),
                ),
                bottomNavigationBar: MoolDestinationNavigationV2(
                  activeId: family.$1,
                  destinationLabel: family.$1,
                  selectedLocalIndex: 0,
                  localActionCount: family.$2,
                  localNavigation: MoolLocalNavigationRail(
                    familyId: family.$1,
                    semanticLabel: '${family.$1} options',
                    activeId: '__none__',
                    actions: [
                      for (var index = 0; index < family.$2; index++)
                        MoolLocalNavigationAction(
                          keyName: 'c22d-${family.$1}-$index',
                          id: 'action-$index',
                          label: 'Action ${index + 1}',
                          icon: Icons.circle_outlined,
                          onPressed: () => taps.add('${family.$1}-$index'),
                        ),
                    ],
                  ),
                  onOpenMool: () {},
                  onOpenAction: (_) {},
                  onOpenChat: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rail = find.byKey(
          ValueKey('moolsocial-${family.$1}-translucent-subaction-family-rail'),
        );
        final globalRail = find.byKey(
          const Key('moolsocial-destination-navigation-stack'),
        );
        expect(rail, findsOneWidget);
        expect(globalRail, findsOneWidget);
        expect(tester.getSize(globalRail).height, MoolMetrics.compactTapTarget);
        expect(
          tester.getRect(rail).bottom,
          closeTo(tester.getRect(globalRail).top, .01),
        );
        final root = find.byKey(const ValueKey('c22d-root'));
        final rootRect = tester.getRect(root);
        final raster = await _capture(tester, const ValueKey('c22d-root'));
        expect(raster.width, tester.getSize(root).width.round());
        expect(raster.height, tester.getSize(root).height.round());
        final railRect = tester.getRect(rail);
        final clusterWidth = MoolLocalNavigationTokens.clusterWidth(
          360,
          family.$2,
        );
        final clusterLeft = (360 - clusterWidth) / 2;
        final sampleY =
            railRect.top + MoolLocalNavigationTokens.controlHeight / 2;
        final outsidePixel = _rgbAt(
          raster,
          (4 - rootRect.left).floor(),
          (sampleY - rootRect.top).floor(),
        );
        final gapPixel = _rgbAt(
          raster,
          (clusterLeft +
                  MoolLocalNavigationTokens.capsuleWidth +
                  MoolLocalNavigationTokens.itemGap / 2)
              .floor(),
          (sampleY - rootRect.top).floor(),
        );
        final capsulePixel = _rgbAt(
          raster,
          (clusterLeft + MoolLocalNavigationTokens.capsuleWidth / 2).floor(),
          (sampleY - rootRect.top).floor(),
        );
        expect(outsidePixel, const [0x24, 0x60, 0x80]);
        expect(gapPixel, const [0x24, 0x60, 0x80]);
        expect(capsulePixel, isNot(const [0x24, 0x60, 0x80]));

        for (var index = 0; index < family.$2; index++) {
          await tester.tap(find.byKey(Key('c22d-${family.$1}-$index')));
          await tester.pump();
        }
        expect(taps.length, family.$2);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<_Raster> _capture(WidgetTester tester, Key key) async {
  final raster = await tester.runAsync<_Raster>(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final result = _Raster(
      data!.buffer.asUint8List(),
      image.width,
      image.height,
    );
    image.dispose();
    return result;
  });
  return raster!;
}

List<int> _rgbAt(_Raster raster, int x, int y) {
  final offset = (y * raster.width + x) * 4;
  final pixels = raster.pixels;
  return [pixels[offset], pixels[offset + 1], pixels[offset + 2]];
}

class _Raster {
  const _Raster(this.pixels, this.width, this.height);

  final Uint8List pixels;
  final int width;
  final int height;
}
