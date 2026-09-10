import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

final class _MediaHttpClient extends Fake implements HttpClient {
  _MediaHttpClient(this.bytes, {this.responses = const {}});
  final Uint8List bytes;
  final Map<Uri, Uint8List> responses;
  final requested = <Uri>[];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requested.add(url);
    return _MediaHttpRequest(responses[url] ?? bytes);
  }
}

final class _MediaCommerce extends Fake implements BuyV2CommerceAdapter {
  _MediaCommerce(this.product, {this.otherProducts = const []});
  final BuyV2Product product;
  final List<BuyV2Product> otherProducts;
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [product, ...otherProducts],
    orders: const [],
    paymentMethods: const {'Cash on Delivery'},
  );
  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: false,
        enabled: false,
        customerMessage: '',
      );
}

final class _MediaHttpRequest extends Fake implements HttpClientRequest {
  _MediaHttpRequest(this.bytes);
  final Uint8List bytes;
  @override
  Future<HttpClientResponse> close() async => _MediaHttpResponse(bytes);
}

final class _MediaHttpResponse extends Fake implements HttpClientResponse {
  _MediaHttpResponse(this.bytes);
  final Uint8List bytes;
  @override
  int get statusCode => HttpStatus.ok;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

Future<Uint8List> _mediaFitFixture(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFE6F2FA),
  );
  canvas.drawRect(
    Rect.fromLTWH(4, 4, width - 8.0, height - 8.0),
    Paint()
      ..color = const Color(0xFF152D5A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8,
  );
  for (final corner in [
    (const Color(0xFFD52D35), Offset(14, 14)),
    (const Color(0xFF27964E), Offset(width - 38.0, 14)),
    (const Color(0xFF245CC4), Offset(14, height - 38.0)),
    (const Color(0xFFE8B52B), Offset(width - 38.0, height - 38.0)),
  ]) {
    canvas.drawRect(corner.$2 & const Size(24, 24), Paint()..color = corner.$1);
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<void> expectThumbnailCornersVisible(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  final frame = tester.getRect(
    find.byKey(const ValueKey('media-thumbnail-frame')),
  );
  final localTopLeft = boundary.globalToLocal(frame.topLeft);
  final counts = await tester.runAsync(() async {
    const ratio = 2.0;
    final rendered = await boundary.toImage(pixelRatio: ratio);
    try {
      final pixels = (await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final counts = <int>[];
      for (final marker in [
        (0, 0, [213, 45, 53]),
        (1, 0, [39, 150, 78]),
        (0, 1, [36, 92, 196]),
        (1, 1, [232, 181, 43]),
      ]) {
        final left = ((localTopLeft.dx + marker.$1 * frame.width / 2) * ratio)
            .floor();
        final top = ((localTopLeft.dy + marker.$2 * frame.height / 2) * ratio)
            .floor();
        final right = (left + frame.width * ratio / 2).floor();
        final bottom = (top + frame.height * ratio / 2).floor();
        var count = 0;
        for (var y = top; y < bottom; y++) {
          for (var x = left; x < right; x++) {
            final offset = (y * rendered.width + x) * 4;
            if (List.generate(
              3,
              (channel) =>
                  (pixels.getUint8(offset + channel) - marker.$3[channel])
                      .abs() <=
                  20,
            ).every((matches) => matches)) {
              count++;
            }
          }
        }
        counts.add(count);
      }
      return counts;
    } finally {
      rendered.dispose();
    }
  });
  expect(
    counts,
    everyElement(greaterThan(0)),
    reason: 'All four image corners must survive the rounded thumbnail frame.',
  );
}

Future<void> capturePack(WidgetTester tester, String label) async {
  if (!const bool.fromEnvironment('BUY_R663_VISUAL_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-cart-capture')),
  );
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    repaint(boundary);
    await captureR66Visual(tester, label);
  } finally {
    debugDisableShadows = previousShadows;
    repaint(boundary);
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R669 supplier media contract', () {
    final product = BuyV2Catalogue.products.first.copyWith(
      storeId: 'supplier-store',
    );

    BuyV2MediaFileMetadata photo({
      String mime = 'image/jpeg',
      int width = 1200,
      int height = 1200,
      int bytes = 1000000,
      int? frames = 1,
      bool normalized = true,
    }) => BuyV2MediaFileMetadata(
      mimeType: mime,
      width: width,
      height: height,
      byteLength: bytes,
      frameCount: frames,
      normalized: normalized,
    );

    BuyV2MediaFileMetadata video({
      String mime = 'video/mp4',
      int width = 1280,
      int height = 720,
      int bytes = 10000000,
      Duration? duration = const Duration(seconds: 60),
      double? rate = 30,
      String? codec = 'h264',
      String? profile = 'baseline',
      String? audio = 'aac-lc',
      bool normalized = true,
    }) => BuyV2MediaFileMetadata(
      mimeType: mime,
      width: width,
      height: height,
      byteLength: bytes,
      normalized: normalized,
      duration: duration,
      frameRate: rate,
      videoCodec: codec,
      videoProfile: profile,
      audioCodec: audio,
    );

    BuyV2ProductMediaAsset asset({
      String id = 'supplier-photo',
      String revision = 'revision-1',
      String? sku,
      String? canonical,
      String? store,
      String workspace = 'supplier-workspace',
      String? source,
      BuyV2MediaFileMetadata? file,
      BuyV2ProductContentMediaKind kind = BuyV2ProductContentMediaKind.network,
      bool bound = true,
      bool hasPoster = true,
      bool hasTranscript = true,
      BuyV2MediaFileMetadata? poster,
    }) {
      final isVideo = kind == BuyV2ProductContentMediaKind.networkVideo;
      return BuyV2ProductMediaAsset(
        id: id,
        label: isVideo ? 'Product demonstration' : 'Supplier pack photo',
        semanticLabel: 'Supplier media of the exact selected pack',
        kind: kind,
        source: source ?? 'https://media.example.com/$id/$revision',
        posterSource: isVideo && hasPoster
            ? 'https://media.example.com/$id/$revision/poster'
            : null,
        transcript: isVideo
            ? (hasTranscript
                  ? 'The supplier shows the pack and its label.'
                  : ' ')
            : null,
        binding: bound
            ? BuyV2ProductMediaBinding(
                supplierWorkspaceId: workspace,
                storeId: store ?? product.storeId!,
                productId: canonical ?? product.canonicalId,
                skuId: sku ?? product.id,
                assetRevision: revision,
                file: file ?? (isVideo ? video() : photo()),
                posterFile: isVideo && hasPoster ? poster ?? photo() : null,
              )
            : null,
      );
    }

    Widget mediaApp(BuyV2Product current, double scale) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: RepaintBoundary(
          key: const ValueKey('r66-cart-capture'),
          child: child!,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SKU / variant preview',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                key: const ValueKey('media-thumbnail-frame'),
                width: 96,
                height: 96,
                child: BuyV2ProductPackshot(product: current),
              ),
              const SizedBox(height: 12),
              const Text('Product image', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                key: const ValueKey('media-detail-frame'),
                width: 280,
                height: 220,
                child: BuyV2ProductPackshot(product: current),
              ),
            ],
          ),
        ),
      ),
    );

    ({_MediaHttpClient client, VoidCallback restore}) installMediaClient(
      Uint8List bytes, {
      Map<Uri, Uint8List> responses = const {},
    }) {
      final previous = debugNetworkImageHttpClientProvider;
      final client = _MediaHttpClient(bytes, responses: responses);
      imageCache.clear();
      imageCache.clearLiveImages();
      debugNetworkImageHttpClientProvider = () => client;
      void restore() {
        debugNetworkImageHttpClientProvider = previous;
        imageCache.clear();
        imageCache.clearLiveImages();
      }

      addTearDown(restore);
      return (client: client, restore: restore);
    }

    Future<void> awaitMedia(WidgetTester tester, bool Function() ready) async {
      for (var tick = 0; tick < 100 && !ready(); tick++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(
        ready(),
        isTrue,
        reason:
            'The local image response must reach its decoded or error state.',
      );
      await tester.pumpAndSettle();
    }

    final encodedPhotos = [
      (
        name: 'jpeg-portrait',
        mime: 'image/jpeg',
        width: 800,
        height: 1600,
        data:
            '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAIBAQEBAQIBAQECAgICAgQDAgICAgUEBAMEBgUGBgYFBgYGBwkIBgcJBwYGCAsICQoKCgoKBggLDAsKDAkKCgr/2wBDAQICAgICAgUDAwUKBwYHCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgr/wAARCAZAAyADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD4vooor+Uz/fwKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPwbooor/tMP8AVgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/jrooor/v8P5XCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/4Az+qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+Ouiiiv+/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/sUooor/gDP6oCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/7/D+VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD+xSiiiv+AM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA//2Q==',
      ),
      (
        name: 'webp-portrait',
        mime: 'image/webp',
        width: 800,
        height: 1600,
        data:
            'UklGRhIKAABXRUJQVlA4IAYKAAAQKAGdASogA0AGPhkMhUIhBCEABABhLS3cLv/AAzv1BfgH4AaoVwD8AP0A/sHOGaBdgP0AzvsAi1Eq81tfTp06dOjpKXc3mtr6dOnTp06dOnTp06dOnTp0338hAyq+nuNRKvNbX06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTfWnxnjPGeM8Z4zxnjPGeM8Z4zxnjPGeM8Z4zxnjPGeM8Z4yQjeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3h0ynuNRKvNbX06dN9/IQMqvp7jUSrzW19OnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06OmJ3N5ra+nTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp03wAAP7/AsOU7mwcdyGuyuVR2cf4qC8b+AqNb3aqnNQw6gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC0/rtj78auDreEl0/wPsvOO0j/v6Bync2DjuQ12VyqOwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
      ),
      (
        name: 'jpeg-landscape',
        mime: 'image/jpeg',
        width: 1600,
        height: 800,
        data:
            '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAIBAQEBAQIBAQECAgICAgQDAgICAgUEBAMEBgUGBgYFBgYGBwkIBgcJBwYGCAsICQoKCgoKBggLDAsKDAkKCgr/2wBDAQICAgICAgUDAwUKBwYHCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgr/wAARCAMgBkADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD4vooor+Uz/fwKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/wC6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD816KKK/qQ/7qAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/ALqAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Siiiiv5bP+FcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAPzXooor+pD/uoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP8AuoCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD9KKKKK/ls/4VwooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA/Neiiiv6kP+6gKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP0oooor+Wz/hXCiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigD8G6KKK/7TD/VgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP466KKK/wC/w/lcKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP7FKKKK/wCAM/qgKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKAP/Z',
      ),
      (
        name: 'webp-landscape',
        mime: 'image/webp',
        width: 1600,
        height: 800,
        data:
            'UklGRhQKAABXRUJQVlA4IAgKAABwKAGdASpABiADPhkMhUIhBCEABABhLS3cLv/AAzv1BfgH4AaoVwD8AP0A/sHOGaBdgP0AzvsAi1Eq81tfTp06dOnTp06dOnTp06dOm+9FOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dHTE7m81tfTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTo6Ync3mtr6dOnTp06dOnTp06dOnTp06ObJvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hvDeG8N4bw3hu/qWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTWmtNaa01prTXHTT3GolXmtr6dOnTp06dOnTp06dOm+/kIGVX09xqJV5ra+nTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp0dMTubzW19OnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOnTp06dOjpidzea2vp06dOnTp06dOnTp06dOnTo4AAP7/AsOU7mwcdyGuyuVR2A7fxUF438BUa3u1VOahh1AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC2/rtj78auDreEl0/wPsvOOwJv/f0DlO5sHHchrsrlUdgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      ),
    ];

    for (final encoded in encodedPhotos) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('decoded ${encoded.name} supplier photo fits at $scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          addTearDown(tester.view.reset);
          final bytes = base64Decode(encoded.data);
          final decodedSize = await tester.runAsync(() async {
            final codec = await ui.instantiateImageCodec(bytes);
            try {
              final frame = await codec.getNextFrame();
              final size = Size(
                frame.image.width.toDouble(),
                frame.image.height.toDouble(),
              );
              frame.image.dispose();
              return size;
            } finally {
              codec.dispose();
            }
          });
          expect(
            decodedSize,
            Size(encoded.width.toDouble(), encoded.height.toDouble()),
          );
          final media = installMediaClient(bytes);
          try {
            final supplied = asset(
              id: 'encoded-${encoded.name}',
              file: photo(
                mime: encoded.mime,
                width: encoded.width,
                height: encoded.height,
                bytes: bytes.length,
              ),
            );
            await tester.pumpWidget(
              mediaApp(product.copyWith(mediaAssets: [supplied]), scale),
            );
            await awaitMedia(
              tester,
              () =>
                  tester
                      .widgetList<RawImage>(find.byType(RawImage))
                      .where((raw) => raw.image != null)
                      .length ==
                  2,
            );
            for (final raw in tester.widgetList<RawImage>(
              find.byType(RawImage),
            )) {
              expect(raw.fit, BoxFit.contain);
              expect(
                raw.image!.height,
                closeTo(raw.image!.width * encoded.height / encoded.width, 1),
              );
            }
            expect(
              tester.getSize(
                find.byKey(const ValueKey('media-thumbnail-frame')),
              ),
              const Size(96, 96),
            );
            expect(
              tester.getSize(find.byKey(const ValueKey('media-detail-frame'))),
              const Size(280, 220),
            );
            expect(find.text('Photo unavailable'), findsNothing);
            expect(
              media.client.requested,
              contains(Uri.parse(supplied.source!)),
            );
            expect(tester.takeException(), isNull);
            await capturePack(tester, 'r669-encoded-${encoded.name}-$scale');
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            media.restore();
          }
        });
      }
    }

    for (final scale in [1.0, 2.0]) {
      for (final shape in [(800, 800), (800, 1600), (1600, 800), (2048, 128)]) {
        testWidgets(
          'decoded supplier photo fits ${shape.$1}x${shape.$2} at $scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(320, 568);
            addTearDown(tester.view.reset);
            final bytes = (await tester.runAsync(
              () => _mediaFitFixture(shape.$1, shape.$2),
            ))!;
            final media = installMediaClient(bytes);
            final client = media.client;
            try {
              final supplied = asset(
                file: photo(
                  mime: 'image/png',
                  width: shape.$1,
                  height: shape.$2,
                  bytes: bytes.length,
                ),
              );
              final current = product.copyWith(mediaAssets: [supplied]);
              await tester.pumpWidget(mediaApp(current, scale));
              await awaitMedia(
                tester,
                () =>
                    tester
                        .widgetList<RawImage>(find.byType(RawImage))
                        .where((image) => image.image != null)
                        .length ==
                    2,
              );
              for (final raw in tester.widgetList<RawImage>(
                find.byType(RawImage),
              )) {
                expect(raw.fit, BoxFit.contain);
                expect(
                  raw.image!.height,
                  closeTo(raw.image!.width * shape.$2 / shape.$1, 1),
                );
              }
              expect(
                tester.getSize(
                  find.byKey(const ValueKey('media-thumbnail-frame')),
                ),
                const Size(96, 96),
              );
              expect(
                tester.getSize(
                  find.byKey(const ValueKey('media-detail-frame')),
                ),
                const Size(280, 220),
              );
              expect(client.requested, isNotEmpty);
              expect(tester.takeException(), isNull);
              if (shape.$1 == shape.$2) {
                await expectThumbnailCornersVisible(tester);
              }
              await capturePack(
                tester,
                'r669-supplier-media-${shape.$1}x${shape.$2}-$scale',
              );
              final requests = client.requested.length;
              await tester.pumpWidget(
                mediaApp(current.copyWith(id: 'other-variant'), scale),
              );
              await tester.pumpAndSettle();
              expect(
                find.byKey(
                  ValueKey(
                    'buy-supplier-photo-${product.id}-${supplied.id}-${supplied.binding!.assetRevision}',
                  ),
                ),
                findsNothing,
              );
              expect(client.requested.length, requests);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            } finally {
              media.restore();
            }
          },
        );
      }

      testWidgets(
        'corrupt supplier photo preserves frames and honest fallback $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          addTearDown(tester.view.reset);
          final media = installMediaClient(Uint8List.fromList([0, 1, 2, 3]));
          try {
            final current = product.copyWith(
              mediaAssets: [asset(file: photo(mime: 'image/png'))],
            );
            await tester.pumpWidget(mediaApp(current, scale));
            final unavailable = find.byKey(
              ValueKey('buy-product-photo-unavailable-${product.id}'),
            );
            await awaitMedia(tester, () => unavailable.evaluate().length == 2);
            expect(
              tester.getSize(
                find.byKey(const ValueKey('media-thumbnail-frame')),
              ),
              const Size(96, 96),
            );
            expect(
              tester.getSize(find.byKey(const ValueKey('media-detail-frame'))),
              const Size(280, 220),
            );
            expect(find.text('Photo unavailable'), findsWidgets);
            expect(tester.takeException(), isNull);
            await capturePack(tester, 'r669-supplier-media-corrupt-$scale');
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            media.restore();
          }
        },
      );

      testWidgets(
        'supplier photos follow product variant zoom Cart and Back $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(320, 568);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final portrait = (await tester.runAsync(
            () => _mediaFitFixture(800, 1600),
          ))!;
          final landscape = (await tester.runAsync(
            () => _mediaFitFixture(1600, 800),
          ))!;
          final responses = <Uri, Uint8List>{};
          final suppliedProducts = <BuyV2Product>[];
          final fixtureCore = BuySession();
          final fixtureSession = BuyV2Session(core: fixtureCore);
          addTearDown(fixtureCore.dispose);
          addTearDown(fixtureSession.dispose);
          for (final pair in [
            ('s-milk', portrait, 800, 1600),
            ('s-milk-500ml', landscape, 1600, 800),
          ]) {
            final base = fixtureSession.product(pair.$1);
            final supplied = asset(
              id: 'photo-${base.id}',
              sku: base.id,
              canonical: base.canonicalId,
              store: 'supplier-store',
              file: photo(
                mime: 'image/png',
                bytes: pair.$2.length,
                width: pair.$3,
                height: pair.$4,
              ),
            );
            responses[Uri.parse(supplied.source!)] = pair.$2;
            suppliedProducts.add(
              base.copyWith(storeId: 'supplier-store', mediaAssets: [supplied]),
            );
          }
          final media = installMediaClient(portrait, responses: responses);
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            commerceAdapter: _MediaCommerce(
              suppliedProducts.first,
              otherProducts: [suppliedProducts.last],
            ),
            reviewDataEnabled: false,
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          try {
            await session.restoreCommerce();
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: MoolTheme.light(),
                builder: (context, child) => r66VisualCaptureRoot(child!),
                home: BuyV2Screen(session: session, onExit: () {}),
              ),
            );
            await tester.pumpAndSettle();
            expect(session.openProduct('s-milk'), isTrue);
            await tester.pump();
            Future<void> verifyGallery(String id, int width, int height) async {
              final gallery = find.byKey(ValueKey('buy-product-gallery-$id'));
              final badge = find.byKey(
                ValueKey('buy-product-gallery-badge-$id'),
              );
              await tester.ensureVisible(badge);
              await tester.pump();
              final image = find.byKey(
                ValueKey('buy-product-gallery-network-photo-$id'),
              );
              await awaitMedia(
                tester,
                () => tester
                    .widgetList<RawImage>(
                      find.descendant(
                        of: image,
                        matching: find.byType(RawImage),
                      ),
                    )
                    .any((raw) => raw.image != null),
              );
              final raw = tester.widget<RawImage>(
                find.descendant(of: image, matching: find.byType(RawImage)),
              );
              expect(raw.fit, BoxFit.contain);
              expect(raw.image!.width, width);
              expect(raw.image!.height, height);
              expect(
                tester.getRect(badge).bottom,
                lessThanOrEqualTo(tester.getRect(gallery).top + .5),
                reason: 'Pack labels must not obscure supplier photo content.',
              );
              expect(
                media.client.requested,
                contains(
                  Uri.parse(
                    session.selectedProduct!.mediaAssets.single.source!,
                  ),
                ),
              );
              expect(tester.takeException(), isNull);
              await capturePack(tester, 'r669-supplier-product-$id-$scale');
            }

            await verifyGallery('s-milk', 800, 1600);
            final zoom = find.byKey(
              const ValueKey('buy-product-media-zoom-s-milk'),
            );
            final center = tester.getCenter(zoom);
            final first = await tester.startGesture(
              center - const Offset(20, 0),
              pointer: 1,
            );
            final second = await tester.startGesture(
              center + const Offset(20, 0),
              pointer: 2,
            );
            await tester.pump();
            for (final distance in [30.0, 45.0, 60.0]) {
              await first.moveTo(center - Offset(distance, 0));
              await second.moveTo(center + Offset(distance, 0));
              await tester.pump(const Duration(milliseconds: 16));
            }
            await first.up();
            await second.up();
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<InteractiveViewer>(zoom)
                  .transformationController!
                  .value
                  .getMaxScaleOnAxis(),
              greaterThan(1),
            );
            await tester.tap(
              find.byKey(const ValueKey('buy-product-media-reset-s-milk')),
            );
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<InteractiveViewer>(zoom)
                  .transformationController!
                  .value
                  .getMaxScaleOnAxis(),
              closeTo(1, .001),
            );
            final variant = find.byKey(
              const ValueKey('buy-product-variant-s-milk-500ml'),
            );
            await tester.scrollUntilVisible(
              variant,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(const PageStorageKey('buy-product-s-milk')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.ensureVisible(variant);
            await tester.pumpAndSettle();
            await tester.tap(variant);
            await tester.pump();
            expect(session.selectedProductId, 's-milk-500ml');
            await verifyGallery('s-milk-500ml', 1600, 800);
            expect(
              find.byKey(
                const ValueKey('buy-product-gallery-network-photo-s-milk'),
              ),
              findsNothing,
            );
            final add = find.byKey(
              const ValueKey('buy-product-primary-s-milk-500ml'),
            );
            await tester.scrollUntilVisible(
              add,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(
                      const PageStorageKey('buy-product-s-milk-500ml'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.ensureVisible(add);
            await tester.pumpAndSettle();
            await tester.tap(add);
            await tester.pumpAndSettle();
            expect(session.quantityFor('s-milk-500ml'), 1);
            expect(session.quantityFor('s-milk'), 0);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(session.quantityFor('s-milk-500ml'), 1);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            media.restore();
          }
        },
      );

      testWidgets('product discloses rejected supplier media at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final current = product.copyWith(
          mediaAssets: [asset(sku: 'different-pack')],
        );
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          commerceAdapter: _MediaCommerce(current),
          reviewDataEnabled: false,
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await session.restoreCommerce();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => r66VisualCaptureRoot(child!),
            home: BuyV2Screen(session: session, onExit: () {}),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.openProduct(current.id), isTrue);
        await tester.pumpAndSettle();
        final notice = find.byKey(
          ValueKey('buy-product-media-notice-${current.id}'),
        );
        await tester.ensureVisible(notice);
        await tester.pumpAndSettle();
        expect(notice.hitTestable(), findsOneWidget);
        expect(
          find.textContaining('could not be displayed for this pack'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await capturePack(
          tester,
          'r669-supplier-media-rejected-product-$scale',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    for (final mime in ['image/jpeg', 'image/png', 'image/webp']) {
      for (final shape in [(1200, 1200), (800, 1600), (1600, 800)]) {
        test('accepts declared static $mime ${shape.$1}x${shape.$2}', () {
          final file = photo(mime: mime, width: shape.$1, height: shape.$2);
          expect(
            BuyV2SupplierMediaPolicy.inputMessage(video: false, file: file),
            isNull,
          );
          expect(
            BuyV2SupplierMediaPolicy.publicationMessage(
              product,
              asset(file: file),
            ),
            isNull,
          );
        });
      }
    }

    final invalidPhotos = <String, BuyV2MediaFileMetadata>{
      'HEIC': photo(mime: 'image/heic'),
      'SVG': photo(mime: 'image/svg+xml'),
      'animated WebP': photo(mime: 'image/webp', frames: 2),
      'unknown frame count': photo(frames: null),
      'missing bytes': photo(bytes: 0),
      'too many bytes': photo(
        bytes: BuyV2SupplierMediaPolicy.maximumImageBytes + 1,
      ),
      'zero width': photo(width: 0),
      'negative height': photo(height: -1),
    };
    for (final entry in invalidPhotos.entries) {
      test('rejects ${entry.key} input and publication', () {
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(
            video: false,
            file: entry.value,
          ),
          isNotNull,
        );
        expect(
          BuyV2SupplierMediaPolicy.publicationMessage(
            product,
            asset(file: entry.value),
          ),
          isNotNull,
        );
      });
    }
    for (final entry in <String, BuyV2MediaFileMetadata>{
      'low resolution': photo(width: 511),
      'oversize side': photo(width: 8193, height: 512),
      'excess decoded pixels': photo(width: 6000, height: 5000),
    }.entries) {
      test('rejects ${entry.key} supplier input', () {
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(
            video: false,
            file: entry.value,
          ),
          isNotNull,
        );
      });
    }
    test('raw input requires a normalized bounded display derivative', () {
      final input = photo(width: 6000, height: 4000, normalized: false);
      expect(
        BuyV2SupplierMediaPolicy.inputMessage(video: false, file: input),
        isNull,
      );
      expect(
        BuyV2SupplierMediaPolicy.publicationMessage(
          product,
          asset(file: input),
        ),
        isNotNull,
      );
      expect(
        BuyV2SupplierMediaPolicy.publicationMessage(
          product,
          asset(file: photo(width: 2049)),
        ),
        isNotNull,
      );
      expect(
        BuyV2SupplierMediaPolicy.publicationMessage(
          product,
          asset(file: photo(width: 2048, height: 2048)),
        ),
        isNotNull,
      );
    });

    for (final shape in [(1280, 720), (720, 1280)]) {
      test('accepts complete MP4 video ${shape.$1}x${shape.$2}', () {
        final file = video(width: shape.$1, height: shape.$2, audio: null);
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(video: true, file: file),
          isNull,
        );
        expect(
          BuyV2SupplierMediaPolicy.publicationMessage(
            product,
            asset(kind: BuyV2ProductContentMediaKind.networkVideo, file: file),
          ),
          isNull,
        );
      });
    }
    for (final entry in <String, BuyV2MediaFileMetadata>{
      'MOV': video(mime: 'video/quicktime'),
      'wrong codec': video(codec: 'hevc'),
      'unknown profile': video(profile: null),
      'wrong audio': video(audio: 'opus'),
      'long video': video(duration: const Duration(seconds: 61)),
      'missing duration': video(duration: null),
      'missing fps': video(rate: null),
      'invalid fps': video(rate: double.nan),
      'high fps': video(rate: 60),
      'large frame': video(width: 1920, height: 1080),
      'too many video bytes': video(
        bytes: BuyV2SupplierMediaPolicy.maximumVideoBytes + 1,
      ),
    }.entries) {
      test('rejects ${entry.key}', () {
        expect(
          BuyV2SupplierMediaPolicy.inputMessage(video: true, file: entry.value),
          isNotNull,
        );
        expect(
          BuyV2SupplierMediaPolicy.publicationMessage(
            product,
            asset(
              kind: BuyV2ProductContentMediaKind.networkVideo,
              file: entry.value,
            ),
          ),
          isNotNull,
        );
      });
    }
    test(
      'video requires matched normalized poster and readable transcript',
      () {
        for (final candidate in [
          asset(
            kind: BuyV2ProductContentMediaKind.networkVideo,
            hasPoster: false,
          ),
          asset(
            kind: BuyV2ProductContentMediaKind.networkVideo,
            hasTranscript: false,
          ),
          asset(
            kind: BuyV2ProductContentMediaKind.networkVideo,
            poster: photo(normalized: false),
          ),
        ]) {
          expect(
            BuyV2SupplierMediaPolicy.publicationMessage(product, candidate),
            isNotNull,
          );
        }
      },
    );

    test(
      'wrong pack supplier source or missing metadata never becomes a supplier photo',
      () {
        for (final candidate in [
          asset(sku: 'another-variant'),
          asset(canonical: 'another-product'),
          asset(store: 'another-store'),
          asset(workspace: ''),
          asset(revision: ''),
          asset(bound: false),
          asset(source: 'http://media.example.com/photo'),
          asset(source: 'https://user:password@media.example.com/photo'),
          asset(kind: BuyV2ProductContentMediaKind.asset),
        ]) {
          expect(
            BuyV2SupplierMediaPolicy.publicationMessage(product, candidate),
            isNotNull,
          );
          final snapshot = const BuyV2CatalogueProductContentAdapter()
              .snapshotFor(product.copyWith(mediaAssets: [candidate]));
          expect(
            snapshot.media.single.kind,
            BuyV2ProductContentMediaKind.cataloguePackshot,
          );
          expect(snapshot.customerMessage, contains('could not be displayed'));
        }
      },
    );
    test(
      'product copy preserves media but another variant cannot inherit its association',
      () {
        final supplied = asset();
        final current = product.copyWith(mediaAssets: [supplied]);
        expect(
          current.copyWith(price: current.price + 1).mediaAssets.single,
          same(supplied),
        );
        final changedVariant = current.copyWith(id: 'another-variant');
        expect(
          const BuyV2CatalogueProductContentAdapter()
              .snapshotFor(changedVariant)
              .media
              .single
              .kind,
          BuyV2ProductContentMediaKind.cataloguePackshot,
        );
      },
    );
    test(
      'gallery takes valid exact-pack media with unique IDs and a bounded list',
      () {
        final valid = asset();
        final snapshot = const BuyV2CatalogueProductContentAdapter()
            .snapshotFor(
              product.copyWith(
                mediaAssets: [
                  valid,
                  valid,
                  asset(sku: 'other'),
                  for (var i = 0; i < 15; i++) asset(id: 'photo-$i'),
                ],
              ),
            );
        expect(snapshot.media.length, BuyV2SupplierMediaPolicy.maximumAssets);
        expect(snapshot.media.first, same(valid));
        expect(
          snapshot.media.map((item) => item.id).toSet().length,
          snapshot.media.length,
        );
        expect(snapshot.customerMessage, isNotNull);
      },
    );
    test('content cache replaces withdrawn or revised exact-SKU media', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      final first = asset();
      final second = asset(revision: 'revision-2');
      final inputs = [first];
      final current = product.copyWith(mediaAssets: inputs);
      expect(session.productContentFor(current).media.single, same(first));
      inputs[0] = second;
      expect(session.productContentFor(current).media.single, same(second));
      expect(
        session
            .productContentFor(current.copyWith(mediaAssets: const []))
            .media
            .single
            .kind,
        BuyV2ProductContentMediaKind.cataloguePackshot,
      );
    });
  });

  for (final offers in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R5 singular trade pack from offers $offers at $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.addProduct('s-milk');
        final otherQuantity = session.quantityFor('s-milk');
        final otherTotal = session.totalForDestination(BuyV2Destination.shop);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 24, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
                disableAnimations: true,
              ),
              child: r66VisualCaptureRoot(child!),
            ),
            home: BuyV2Screen(session: session),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            ValueKey(
              offers ? 'buy-local-tab-offers' : 'buy-local-tab-wholesale',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sourceId = offers ? 'w-oil' : 'w-rice';
        final selectedId = offers ? 'w-oil-10l' : 'w-rice-50kg';
        if (!offers) {
          await tester.tap(find.byKey(const ValueKey('buy-search-control')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('buy-search-field')),
            'rice',
          );
          await tester.pumpAndSettle();
        }
        final source = session.product(sourceId);
        final sourceCard = find.byKey(ValueKey('buy-product-$sourceId'));
        await Scrollable.ensureVisible(
          tester.element(sourceCard),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expect(sourceCard.hitTestable(), findsOneWidget);
        await tester.tap(sourceCard);
        await tester.pumpAndSettle();
        final selector = find.byKey(
          ValueKey('buy-product-variants-${source.canonicalId}'),
        );
        await tester.scrollUntilVisible(
          selector,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$sourceId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final variant = find.byKey(ValueKey('buy-product-variant-$selectedId'));
        await tester.ensureVisible(variant);
        await tester.pumpAndSettle();
        await tester.tap(variant);
        await tester.pumpAndSettle();
        final selected = session.selectedProduct!;
        expect(selected.id, selectedId);
        expect(selected.minimumOrder, 1);
        expect(selected.price, offers ? 1580 : 3200);
        expect(selected.seller, source.seller);
        expect(session.quantityFor(sourceId), 0);
        final label = find.text('Minimum 1 pack · ${selected.pack} each');
        expect(label, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
          isFalse,
        );
        final addLabel = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              (widget.properties.label ?? '').startsWith(
                'Add minimum order of 1 pack of ',
              ),
        );
        expect(addLabel, findsOneWidget);
        expect(find.textContaining(RegExp(r'\b1 packs\b')), findsNothing);
        await capturePack(tester, 'r5-pack-$offers-$scale-minimum');
        final trade = find.text('MOQ 1 pack');
        await tester.scrollUntilVisible(
          trade,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final priceSummary = find.byKey(
          ValueKey('buy-wholesale-price-summary-$selectedId'),
        );
        expect(
          find.descendant(
            of: priceSummary,
            matching: find.text('${selected.pack} · ${selected.unitPrice}'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: priceSummary, matching: trade),
          findsOneWidget,
        );
        final tradeSemantics = find.byKey(
          ValueKey('buy-wholesale-trade-decision-$selectedId'),
        );
        await tester.scrollUntilVisible(
          tradeSemantics,
          160,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-$selectedId')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Semantics>(tradeSemantics).properties.label,
          contains('Minimum order 1 pack.'),
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-trade');
        final add = find.byKey(ValueKey('buy-product-primary-$selectedId'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(add.hitTestable(), findsOneWidget);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(selectedId), 1);
        expect(
          session.totalForDestination(BuyV2Destination.wholesale),
          selected.price,
        );
        expect(find.text('1 pack in Cart'), findsOneWidget);
        await capturePack(tester, 'r5-pack-$offers-$scale-one-in-cart');
        final stepper = find.byKey(
          ValueKey('buy-product-quantity-$selectedId'),
        );
        await tester.tap(
          find.descendant(of: stepper, matching: find.byTooltip('Add one')),
        );
        await tester.pumpAndSettle();
        expect(session.quantityFor(selectedId), 2);
        expect(find.text('2 packs in Cart'), findsOneWidget);
        expect(
          session.totalForDestination(BuyV2Destination.wholesale),
          selected.price * 2,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-two-in-cart');
        await tester.tap(
          find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').contains(
                  'Minimum order 1 packs.',
                ),
          ),
          findsNothing,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                (widget.properties.label ?? '').contains(
                  'Minimum order 1 pack.',
                ),
          ),
          findsWidgets,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-cart');
        final cartFacts = find.byKey(
          ValueKey('buy-wholesale-cart-line-facts-$selectedId'),
        );
        await Scrollable.ensureVisible(
          tester.element(cartFacts),
          alignment: .45,
        );
        await tester.pumpAndSettle();
        final cartPackLabel = find.descendant(
          of: cartFacts,
          matching: find.textContaining('MOQ 1 pack'),
        );
        expect(cartPackLabel.hitTestable(), findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(cartPackLabel).didExceedMaxLines,
          isFalse,
        );
        await capturePack(tester, 'r5-pack-$offers-$scale-cart-moq');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, selectedId);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        if (offers) {
          final collection = find.byKey(const PageStorageKey('buy-offers'));
          expect(collection, findsOneWidget);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('buy-offers-publisher-summary')),
            -200,
            scrollable: find
                .descendant(of: collection, matching: find.byType(Scrollable))
                .first,
          );
        }
        expect(
          find.byKey(const ValueKey('buy-offers-publisher-summary')),
          offers ? findsOneWidget : findsNothing,
        );
        expect(session.quantityFor('s-milk'), otherQuantity);
        expect(session.totalForDestination(BuyV2Destination.shop), otherTotal);
        expect(session.quantityFor(selectedId), 2);
        await capturePack(tester, 'r5-pack-$offers-$scale-return');
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 1.4, 2.0]) {
    testWidgets(
      'product options preserve exact pack Cart and Back state at $scale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        expect(session.openProduct('s-milk'), isTrue);

        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (_, child) => r66VisualCaptureRoot(child!),
            home: BuyV2Screen(
              session: session,
              initialDestination: session.destination,
              initialView: session.view,
              productId: session.selectedProductId,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final selector = find.byKey(
          const ValueKey('buy-product-variants-milk'),
        );
        await tester.scrollUntilVisible(
          selector,
          180,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('buy-product-s-milk')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(selector, findsOneWidget);
        for (final id in const ['s-milk', 's-milk-500ml', 's-milk-2l']) {
          expect(
            find.byKey(ValueKey('buy-product-variant-$id')),
            findsOneWidget,
          );
        }

        final halfLitre = find.byKey(
          const ValueKey('buy-product-variant-s-milk-500ml'),
        );
        await tester.ensureVisible(halfLitre);
        await tester.pumpAndSettle();
        await tester.tap(halfLitre);
        await tester.pumpAndSettle();
        expect(session.selectedProduct?.id, 's-milk-500ml');
        expect(session.selectedProduct?.pack, '500 ml pouch');
        expect(session.selectedProduct?.price, 35);
        expect(session.selectedProduct?.unitPrice, '₹70/L');
        final badge = find.byKey(
          const ValueKey('buy-product-gallery-badge-s-milk-500ml'),
        );
        await tester.ensureVisible(badge);
        await tester.pumpAndSettle();
        final badgeText = find.descendant(
          of: badge,
          matching: find.text('500 ml pack'),
        );
        expect(badgeText, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(badgeText).didExceedMaxLines,
          isFalse,
        );
        expect(find.text('Quick local choice'), findsNothing);
        await capturePack(tester, 'r669-milk-variant-badge-$scale');
        expect(find.text('500 ml pouch · ₹70/L'), findsOneWidget);

        final add = find.byKey(
          const ValueKey('buy-product-primary-s-milk-500ml'),
        );
        await tester.scrollUntilVisible(
          add,
          180,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const PageStorageKey('buy-product-s-milk-500ml'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-product-hero-delivery-s-milk-500ml')),
          findsOneWidget,
        );
        expect(find.textContaining('Standard/courier delivery'), findsWidgets);
        expect(find.text('Quick local choice'), findsNothing);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor('s-milk-500ml'), 1);
        expect(session.quantityFor('s-milk'), 0);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view.name, 'catalogue');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
