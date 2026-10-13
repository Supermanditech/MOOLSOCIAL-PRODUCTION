import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/social/social_v2_design.dart';

void main() {
  testWidgets(
    'shared Social input sheet keeps feed reply and completion action above keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      tester.view.viewPadding = const FakeViewPadding(bottom: 44);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                key: const Key('open-social-input-sheet'),
                onPressed: () => showSocialV2Sheet(
                  context,
                  title: 'Replies',
                  subtitle: 'Public replies to this post',
                  children: [
                    for (var index = 0; index < 5; index++)
                      Text(
                        'Existing public reply ${index + 1} stays readable before the composer.',
                      ),
                    const TextField(
                      key: Key('social-audit-reply-field'),
                      autofocus: true,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Write a public reply',
                      ),
                    ),
                    const FilledButton(
                      key: Key('social-audit-reply-submit'),
                      onPressed: null,
                      child: Text('Post reply'),
                    ),
                  ],
                ),
                child: const Text('Open replies'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-social-input-sheet')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      final keyboardTop = 500.0;
      final visibleSurface = find.byKey(
        const Key('social-v2-sheet-visible-surface'),
      );
      expect(
        tester.getBottomRight(visibleSurface).dy,
        lessThanOrEqualTo(keyboardTop),
      );
      final replyField = find.byKey(const Key('social-audit-reply-field'));
      await tester.ensureVisible(replyField);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(replyField).dy,
        lessThanOrEqualTo(keyboardTop),
      );

      final submit = find.byKey(const Key('social-audit-reply-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(keyboardTop));
      expect(tester.takeException(), isNull);
    },
  );
}
