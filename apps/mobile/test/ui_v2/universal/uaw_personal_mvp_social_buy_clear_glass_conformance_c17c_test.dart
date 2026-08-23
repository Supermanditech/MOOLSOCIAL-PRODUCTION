import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Social uses four unclipped media-glass controls and provider semantics',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 220));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 220),
              textScaler: TextScaler.linear(2),
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF11092A), Color(0xFF4A1768)],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _SocialRailHarness(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final wrapper = find.byKey(const Key('screen04-context-tabs'));
      final rail = find.descendant(
        of: wrapper,
        matching: find.byType(MoolLocalNavigationRail),
      );
      expect(
        tester.getSize(wrapper).height,
        MoolLocalNavigationTokens.railHeight,
      );
      expect(tester.getSize(rail).height, MoolLocalNavigationTokens.railHeight);
      expect(
        tester.widget<MoolLocalNavigationRail>(rail).surfaceTone,
        MoolLocalNavigationSurfaceTone.media,
      );
      expect(
        find.descendant(of: wrapper, matching: find.byType(BackdropFilter)),
        findsNWidgets(4),
      );
      expect(
        find.descendant(of: wrapper, matching: find.byType(SvgPicture)),
        findsNWidgets(2),
      );
      _expectProfessionalFamily(
        tester,
        owner: wrapper,
        actionKeys: const [
          'screen04-rail-shorts',
          'screen04-rail-videos',
          'screen04-rail-feed',
          'screen04-rail-create',
        ],
        labels: const ['Shorts', 'Videos', 'Feed', 'Create'],
        tone: MoolLocalNavigationSurfaceTone.media,
      );

      var node = tester.getSemantics(
        find.byKey(const Key('screen04-rail-shorts')),
      );
      expect(node.label, 'YouTube Shorts, current');
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      await tester.tap(find.byKey(const Key('screen04-rail-videos')));
      await tester.pumpAndSettle();
      node = tester.getSemantics(find.byKey(const Key('screen04-rail-videos')));
      expect(node.label, 'YouTube Videos, current');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Buy uses the one connected launcher with no blocking local rail',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      final routes = <String>[];
      addTearDown(session.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            );
          },
          home: BuyV2Screen(
            session: session,
            onOpenMainAction: (action) => routes.add(action.route),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('moolsocial-buy-translucent-subaction-family-rail'),
        ),
        findsNothing,
      );
      final launcher = find.byKey(const Key('mool-home-launcher'));
      expect(launcher, findsOneWidget);
      expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
      await tester.tap(launcher);
      await tester.pumpAndSettle();
      final connected = find.byKey(
        const Key('mool-connected-action-navigator'),
      );
      expect(connected, findsOneWidget);
      for (final action in const ['shop', 'wholesale', 'medicine', 'orders']) {
        final target = find.byKey(Key('mool-navigator-buy-$action'));
        expect(target, findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      }
      expect(
        find.descendant(of: connected, matching: find.byType(BackdropFilter)),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('mool-navigator-buy-wholesale')),
      );
      await tester.pumpAndSettle();
      expect(routes, ['/app/buy?sub=wholesale']);
      expect(tester.takeException(), isNull);
    },
  );
}

void _expectProfessionalFamily(
  WidgetTester tester, {
  required Finder owner,
  required List<String> actionKeys,
  required List<String> labels,
  required MoolLocalNavigationSurfaceTone tone,
}) {
  expect(
    find.descendant(of: owner, matching: find.byType(Scrollable)),
    findsNothing,
  );
  expect(
    find.descendant(of: owner, matching: find.byType(Expanded)),
    findsNothing,
  );
  for (final keyName in actionKeys) {
    final action = find.byKey(Key(keyName));
    expect(
      tester.getSize(action).width,
      greaterThanOrEqualTo(48),
      reason: keyName,
    );
    expect(
      tester.getSize(action).height,
      greaterThanOrEqualTo(48),
      reason: keyName,
    );
  }
  for (final label in labels) {
    final text = find.descendant(of: owner, matching: find.text(label));
    expect(text, findsOneWidget, reason: label);
    final style = tester.widget<Text>(text).style!;
    expect(style.fontSize, MoolLocalNavigationTokens.labelFontSize);
    expect(style.fontWeight!.value, greaterThanOrEqualTo(700));
    expect(style.color, MoolLocalNavigationTokens.foreground(tone));
    expect(
      find.ancestor(of: text, matching: find.byType(FittedBox)),
      findsOneWidget,
      reason: label,
    );
  }
  for (final index in List.generate(actionKeys.length, (index) => index)) {
    final id = switch (actionKeys[index]) {
      'screen04-rail-shorts' => 'shorts',
      'screen04-rail-videos' => 'videos',
      'screen04-rail-feed' => 'feed',
      'screen04-rail-create' => 'create',
      'buy-local-tab-shop' => 'shop',
      'buy-local-tab-wholesale' => 'wholesale',
      'buy-local-tab-medicine' => 'medicine',
      _ => 'orders',
    };
    final glass = tester.widget<AnimatedContainer>(
      find.byKey(Key('moolsocial-local-$id-glass-control')),
    );
    final decoration = glass.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    final selected =
        tester
            .getSemantics(find.byKey(Key(actionKeys[index])))
            .flagsCollection
            .isSelected ==
        Tristate.isTrue;
    expect(decoration.color, isNull, reason: id);
    expect(gradient.colors.every((color) => color.a < 1), isTrue, reason: id);
    expect(
      gradient,
      MoolLocalNavigationTokens.glassGradient(
        tone: tone,
        selected: selected,
        pressed: false,
      ),
      reason: id,
    );
  }
}

class _SocialRailHarness extends StatefulWidget {
  const _SocialRailHarness();

  @override
  State<_SocialRailHarness> createState() => _SocialRailHarnessState();
}

class _SocialRailHarnessState extends State<_SocialRailHarness> {
  String choice = 'shorts';

  @override
  Widget build(BuildContext context) {
    return Screen04ContextTabs(
      world: screen04World('social'),
      choice: choice,
      onChoice: (next) => setState(() => choice = next),
    );
  }
}
