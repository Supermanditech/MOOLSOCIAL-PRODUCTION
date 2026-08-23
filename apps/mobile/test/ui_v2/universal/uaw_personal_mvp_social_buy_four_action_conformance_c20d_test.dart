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

const _widths = [320.0, 360.0, 390.0, 412.0, 430.0];
const _textScales = [1.0, 1.3];

const _socialActions = <_ActionSpec>[
  _ActionSpec('screen04-rail-shorts', 'shorts', 'Shorts'),
  _ActionSpec('screen04-rail-videos', 'videos', 'Videos'),
  _ActionSpec('screen04-rail-feed', 'feed', 'Feed'),
  _ActionSpec('screen04-rail-create', 'create', 'Create'),
];

const _buyActions = <_ActionSpec>[
  _ActionSpec('buy-local-tab-shop', 'shop', 'Shop'),
  _ActionSpec('buy-local-tab-wholesale', 'wholesale', 'Wholesale'),
  _ActionSpec('buy-local-tab-medicine', 'medicine', 'Medicine'),
  _ActionSpec('buy-local-tab-orders', 'orders', 'Orders'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Social qualifies four media-glass actions at five widths and two text scales',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in _widths) {
        for (final textScale in _textScales) {
          await tester.binding.setSurfaceSize(Size(width, 220));
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 220),
                  textScaler: TextScaler.linear(textScale),
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF11092A), Color(0xFF4A1768)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _SocialRailHarness(
                        key: ValueKey('social-$width-$textScale'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final owner = find.byKey(const Key('screen04-context-tabs'));
          expect(
            find.descendant(of: owner, matching: find.byType(SvgPicture)),
            findsNWidgets(2),
          );
          for (final selected in _socialActions) {
            if (selected != _socialActions.first) {
              await tester.tap(find.byKey(Key(selected.keyName)));
              await tester.pumpAndSettle();
            }
            _expectFourActionFamily(
              tester,
              owner: owner,
              actions: _socialActions,
              selectedId: selected.id,
              tone: MoolLocalNavigationSurfaceTone.media,
              width: width,
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'Buy qualifies four connected actions at five widths and two text scales',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final sessions = <BuyV2Session>[];
      addTearDown(() {
        for (final session in sessions) {
          session.dispose();
        }
      });

      for (final width in _widths) {
        for (final textScale in _textScales) {
          await tester.binding.setSurfaceSize(Size(width, 700));
          final session = BuyV2Session(core: BuySession());
          final routes = <String>[];
          sessions.add(session);
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(textScale),
                  ),
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
          for (final action in _buyActions) {
            await tester.tap(find.byKey(const Key('mool-home-launcher')));
            await tester.pumpAndSettle();
            final owner = find.byKey(
              const Key('mool-connected-action-navigator'),
            );
            expect(owner, findsOneWidget);
            for (final candidate in _buyActions) {
              final target = find.byKey(
                Key('mool-navigator-buy-${candidate.id}'),
              );
              expect(target, findsOneWidget);
              expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
            }
            await tester.tap(
              find.byKey(Key('mool-navigator-buy-${action.id}')),
            );
            await tester.pumpAndSettle();
            expect(
              routes.last,
              '/app/buy?sub=${action.id}',
              reason: '${action.id} at $width/$textScale',
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets(
    'Social and Buy keep finite state motion and immediate reduced motion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 700), disableAnimations: true),
            child: Material(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _SocialRailHarness(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      _expectImmediateMotion('shorts', tester);

      final session = BuyV2Session(core: BuySession());
      final routes = <String>[];
      addTearDown(session.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 700),
              disableAnimations: true,
            ),
            child: BuyV2Screen(
              session: session,
              onOpenMainAction: (action) => routes.add(action.route),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const Key('mool-home-launcher-press-motion')),
            )
            .duration,
        Duration.zero,
      );
      await tester.tap(find.byKey(const Key('mool-home-launcher')));
      await tester.pump();
      final wholesale = find.byKey(const Key('mool-navigator-buy-wholesale'));
      final node = tester.getSemantics(wholesale);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(wholesale);
      await tester.pump();
      expect(routes, ['/app/buy?sub=wholesale']);
    },
  );
}

void _expectFourActionFamily(
  WidgetTester tester, {
  required Finder owner,
  required List<_ActionSpec> actions,
  required String selectedId,
  required MoolLocalNavigationSurfaceTone tone,
  required double width,
}) {
  expect(tester.getSize(owner).height, MoolLocalNavigationTokens.railHeight);
  final cluster = find.descendant(
    of: owner,
    matching: find.byKey(
      const Key('moolsocial-local-navigation-compact-cluster'),
    ),
  );
  expect(
    tester.getSize(cluster).width,
    MoolLocalNavigationTokens.clusterWidth(width, 4),
  );
  expect(
    find.descendant(of: owner, matching: find.byType(Scrollable)),
    findsNothing,
  );
  expect(
    find.descendant(of: owner, matching: find.byType(Expanded)),
    findsNothing,
  );
  expect(
    find.descendant(of: owner, matching: find.byType(BackdropFilter)),
    findsNWidgets(4),
  );

  for (final action in actions) {
    final actionFinder = find.byKey(Key(action.keyName));
    expect(tester.getSize(actionFinder).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(actionFinder).height, 48);
    final selected = action.id == selectedId;
    final semantics = tester.getSemantics(actionFinder);
    expect(
      semantics.flagsCollection.isSelected,
      selected ? Tristate.isTrue : Tristate.isFalse,
    );
    expect(
      semantics.getSemanticsData().hasAction(SemanticsAction.tap),
      !selected,
    );

    final label = find.descendant(of: owner, matching: find.text(action.label));
    expect(label, findsOneWidget);
    final text = tester.widget<Text>(label);
    expect(text.maxLines, 1);
    expect(text.style?.fontSize, MoolLocalNavigationTokens.labelFontSize);
    expect(text.style?.fontWeight, MoolLocalNavigationTokens.labelFontWeight);
    expect(text.style?.color, MoolLocalNavigationTokens.foreground(tone));
    expect(
      find.ancestor(of: label, matching: find.byType(FittedBox)),
      findsOneWidget,
    );

    final glass = tester.widget<AnimatedContainer>(
      find.byKey(Key('moolsocial-local-${action.id}-glass-control')),
    );
    final decoration = glass.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(decoration.color, isNull);
    expect(
      gradient,
      MoolLocalNavigationTokens.glassGradient(
        tone: tone,
        selected: selected,
        pressed: false,
      ),
    );
    expect(gradient.colors.every((color) => color.a < 1), isTrue);
    final backgrounds = tone == MoolLocalNavigationSurfaceTone.media
        ? const [Colors.white, Color(0xFFFFA24A), Color(0xFF111827)]
        : const [Colors.white, Color(0xFFFF8A00), MoolBrand.identityNavy];
    for (final background in backgrounds) {
      for (final stop in gradient.colors) {
        expect(
          _contrastRatio(
            MoolLocalNavigationTokens.foreground(tone),
            Color.alphaBlend(stop, background),
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  }
}

void _expectImmediateMotion(String id, WidgetTester tester) {
  expect(
    tester
        .widget<AnimatedScale>(
          find.byKey(Key('moolsocial-local-$id-pressed-scale')),
        )
        .duration,
    Duration.zero,
  );
  for (final suffix in const ['selection', 'glass-control']) {
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(Key('moolsocial-local-$id-$suffix')),
          )
          .duration,
      Duration.zero,
    );
  }
  for (final suffix in const ['selected', 'pressed']) {
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(Key('moolsocial-local-$id-$suffix-inner-chroma')),
          )
          .duration,
      Duration.zero,
    );
  }
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final light = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final dark = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (light + .05) / (dark + .05);
}

class _SocialRailHarness extends StatefulWidget {
  const _SocialRailHarness({super.key});

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

class _ActionSpec {
  const _ActionSpec(this.keyName, this.id, this.label);

  final String keyName;
  final String id;
  final String label;
}
