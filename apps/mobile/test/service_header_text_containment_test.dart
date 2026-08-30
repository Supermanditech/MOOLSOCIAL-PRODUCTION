import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_service_home.dart';

void main() {
  testWidgets('compact service header keeps full customer meaning', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 220,
              child: MoolServiceHeaderTitle(
                title: 'Bus',
                subtitle: 'Compare routes before booking',
                subtitleKey: Key('subtitle'),
              ),
            ),
          ),
        ),
      ),
    );

    final subtitle = tester.widget<Text>(find.byKey(const Key('subtitle')));
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(const Key('subtitle')),
    );
    expect(subtitle.maxLines, 2);
    expect(subtitle.overflow, TextOverflow.clip);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
