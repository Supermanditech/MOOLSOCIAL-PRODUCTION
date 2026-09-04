import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_product_video.dart';
import 'package:video_player/video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final product = BuyV2Catalogue.products.firstWhere(
    (candidate) => candidate.id == 's-milk',
  );

  BuyV2ProductMediaAsset video({String? source}) => BuyV2ProductMediaAsset(
    id: 's-milk-video',
    label: 'See the sealed pack',
    semanticLabel: 'Toned fresh milk sealed-pack product video',
    kind: BuyV2ProductContentMediaKind.networkVideo,
    source: source ?? 'https://media.moolsocial.test/products/s-milk.mp4',
    posterSource: 'https://media.moolsocial.test/products/s-milk-poster.jpg',
    transcript:
        'The video shows the sealed one litre milk pouch from the front and back.',
  );

  Widget app(
    BuyV2ProductMediaAsset media, {
    required BuyV2ProductVideoControllerFactory controllerFactory,
    bool active = true,
  }) => MaterialApp(
    theme: MoolTheme.light(),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          height: 240,
          child: BuyV2ProductVideo(
            product: product,
            media: media,
            active: active,
            controllerFactory: controllerFactory,
            videoBuilder: (_) => const ColoredBox(
              key: ValueKey('fake-product-video-surface'),
              color: Colors.black,
            ),
          ),
        ),
      ),
    ),
  );

  test('authoritative video media requires a transcript', () {
    expect(
      () => BuyV2ProductMediaAsset(
        id: 'video-without-transcript',
        label: 'Product video',
        semanticLabel: 'Product video',
        kind: BuyV2ProductContentMediaKind.networkVideo,
        source: 'https://media.moolsocial.test/product.mp4',
      ),
      throwsAssertionError,
    );
  });

  testWidgets('product video plays, pauses, mutes and exposes transcript', (
    tester,
  ) async {
    final controller = _FakeVideoController();
    await tester.pumpWidget(app(video(), controllerFactory: (_) => controller));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fake-product-video-surface')),
      findsOneWidget,
    );
    final play = find.byKey(
      const ValueKey('buy-product-video-play-s-milk-video'),
    );
    await tester.tap(play);
    await tester.pump();
    expect(controller.playCalls, 1);
    expect(controller.value.isPlaying, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('buy-product-video-mute-s-milk-video')),
    );
    await tester.pump();
    expect(controller.lastVolume, 0);

    await tester.tap(
      find.byKey(
        const ValueKey('buy-product-video-transcript-button-s-milk-video'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Video transcript'), findsOneWidget);
    expect(
      find.text(
        'The video shows the sealed one litre milk pouch from the front and back.',
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-product-video-transcript-close')),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      app(video(), controllerFactory: (_) => controller, active: false),
    );
    await tester.pump();
    expect(controller.pauseCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('invalid video source fails truthfully and keeps transcript', (
    tester,
  ) async {
    var factoryCalls = 0;
    await tester.pumpWidget(
      app(
        video(source: 'not-a-network-video'),
        controllerFactory: (_) {
          factoryCalls += 1;
          return _FakeVideoController();
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(factoryCalls, 0);
    expect(
      find.text('This product video is unavailable right now.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-video-retry-s-milk-video')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey('buy-product-video-error-transcript-s-milk-video'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Video transcript'), findsOneWidget);
  });
}

final class _FakeVideoController extends VideoPlayerController {
  _FakeVideoController()
    : super.networkUrl(
        Uri.parse('https://media.moolsocial.test/products/fake.mp4'),
      );

  int playCalls = 0;
  int pauseCalls = 0;
  double lastVolume = 1;

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      duration: const Duration(seconds: 90),
      size: const Size(1280, 720),
      isInitialized: true,
    );
  }

  @override
  Future<void> play() async {
    playCalls += 1;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration moment) async {
    value = value.copyWith(position: moment);
  }

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

}
