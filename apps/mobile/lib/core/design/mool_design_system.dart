import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'mool_colors.dart';

/// App-wide brand identity that must remain stable across every product
/// vertical. Mool is a service launcher, not a second MoolSocial logo.
abstract final class MoolBrand {
  static const String wordmark = 'MoolSocial';
  static const String staticBrandOutcome = wordmark;
  static const IconData moolLauncherIcon = Icons.grid_view_rounded;
  static const Color identityNavy = MoolColors.navy;
  static const Color identitySaffron = MoolColors.orange;
  static const Color identityWhite = Colors.white;
  static const Color identityGreen = MoolColors.success;
  static const List<Color> identityPalette = <Color>[
    identityNavy,
    identitySaffron,
    identityWhite,
    identityGreen,
  ];

  static bool isIdentityColor(Color color) {
    return identityPalette.any(
      (allowed) => allowed.toARGB32() == color.toARGB32(),
    );
  }
}

/// Shared full-app design tokens.
///
/// Product screens must use these values instead of introducing local spacing,
/// radius, motion or tap-target constants. See
/// docs/design/APPLE-INSPIRED-PRODUCT-DESIGN-MEMORY.md.
abstract final class MoolSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class MoolRadii {
  static const double control = 12;
  static const double card = 18;
  static const double sheet = 28;
  static const double floating = 24;
  static const double capsule = 999;
}

abstract final class MoolMetrics {
  /// Apple Human Interface Guidance minimum interactive size.
  static const double minimumTapTarget = 44;
  static const double compactTapTarget = 48;
  static const double readableNavigationCellWidth = 60;
  static const double maximumContentWidth = 440;
  static const double bottomNavigationHeight = 64;
}

/// One restrained platform-adaptive Back affordance for every app vertical.
class MoolNativeBackButton extends StatelessWidget {
  const MoolNativeBackButton({
    required this.keyName,
    required this.onPressed,
    this.foregroundColor = MoolColors.ink,
    super.key,
  });

  final String keyName;
  final VoidCallback onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => IconButton(
    key: ValueKey(keyName),
    tooltip: 'Back',
    onPressed: onPressed,
    constraints: const BoxConstraints.tightFor(
      width: MoolMetrics.minimumTapTarget,
      height: MoolMetrics.minimumTapTarget,
    ),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: Colors.transparent,
      overlayColor: foregroundColor.withValues(alpha: .08),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MoolRadii.control),
      ),
    ),
    icon: const BackButtonIcon(),
  );
}

abstract final class MoolMotion {
  static const Duration quick = Duration(milliseconds: 160);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration deliberate = Duration(milliseconds: 360);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve change = Curves.easeInOutCubic;

  static Duration accessible(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }

  static bool isReduced(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }
}

abstract final class MoolShadows {
  static const floating = [
    BoxShadow(color: Color(0x18000036), blurRadius: 32, offset: Offset(0, 16)),
    BoxShadow(color: Color(0x0A000036), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const card = [
    BoxShadow(color: Color(0x0F000036), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x08000036), blurRadius: 4, offset: Offset(0, 1)),
  ];
}

/// A restrained translucent surface for persistent navigation and temporary
/// command palettes. The content remains the visual focus.
class MoolGlassSurface extends StatelessWidget {
  const MoolGlassSurface({
    required this.child,
    this.dark = false,
    this.padding = const EdgeInsets.all(MoolSpacing.xs),
    this.borderRadius = MoolRadii.floating,
    this.insetBorder = true,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final bool dark;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool insetBorder;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final border = Border.all(
      color: dark
          ? Colors.white.withValues(alpha: .16)
          : const Color(0x1F000080),
    );
    final surface = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedContainer(
          duration: MoolMotion.accessible(context, MoolMotion.standard),
          curve: MoolMotion.change,
          padding: padding,
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xE812124F)
                : Colors.white.withValues(alpha: .88),
            border: insetBorder ? border : null,
            borderRadius: radius,
            boxShadow: MoolShadows.floating,
          ),
          foregroundDecoration: insetBorder
              ? null
              : BoxDecoration(border: border, borderRadius: radius),
          child: child,
        ),
      ),
    );

    if (semanticLabel == null) return surface;
    return Semantics(container: true, label: semanticLabel, child: surface);
  }
}

/// The standard content surface for every MoolSocial vertical.
///
/// It keeps hierarchy calm, provides a restrained pressed response and avoids
/// the heavy outlined-card treatment that made earlier prototype screens feel
/// like internal forms.
class MoolCardSurface extends StatefulWidget {
  const MoolCardSurface({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<MoolCardSurface> createState() => _MoolCardSurfaceState();
}

class _MoolCardSurfaceState extends State<MoolCardSurface> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(MoolRadii.card);
    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      excludeSemantics: widget.semanticLabel != null,
      child: AnimatedScale(
        scale: pressed ? .985 : 1,
        duration: MoolMotion.accessible(context, MoolMotion.quick),
        curve: MoolMotion.change,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: radius,
            border: Border.all(color: const Color(0x14000080)),
            boxShadow: MoolShadows.card,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: widget.onTap == null
                    ? null
                    : (value) => setState(() => pressed = value),
                splashColor: MoolColors.royal.withValues(alpha: .08),
                highlightColor: MoolColors.royal.withValues(alpha: .04),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A reusable selected/unselected capsule for focused sub-actions.
class MoolSegment extends StatelessWidget {
  const MoolSegment({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? MoolColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(MoolRadii.capsule),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: MoolMetrics.minimumTapTarget,
              minHeight: MoolMetrics.minimumTapTarget,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: icon == null ? MoolSpacing.sm : MoolSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 17,
                      color: selected ? Colors.white : MoolColors.navy,
                    ),
                    const SizedBox(width: MoolSpacing.xxs),
                  ],
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: selected ? Colors.white : MoolColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoolDockAction {
  const MoolDockAction({
    required this.keyName,
    required this.id,
    required this.label,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
    this.badgeCount = 0,
    this.anchorKey,
    this.disclosureExpanded,
  });

  final String keyName;
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final int badgeCount;
  final GlobalKey? anchorKey;
  final bool? disclosureExpanded;
}

@immutable
class MoolLocalNavigationAction {
  const MoolLocalNavigationAction({
    required this.keyName,
    required this.id,
    required this.label,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
    this.iconAsset,
  });

  final String keyName;
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? iconAsset;
}

enum MoolLocalNavigationSurfaceTone { light, media }

/// One professional local-navigation language for every customer-outcome
/// family. These tokens also locate the exact compact selected-action center
/// used by the family-connection wave.
abstract final class MoolLocalNavigationTokens {
  static const double horizontalInset = 0;
  static const double itemGap = MoolSpacing.xs;
  static const double compactItemGap = 2;
  static const double destinationRailHeight = 58;
  static const double railHeight = destinationRailHeight;
  static const double controlHeight = MoolMetrics.compactTapTarget;
  static const double capsuleWidth = 72;
  static const double controlRadius = 24;
  static const double backdropBlurSigma = 20;
  static const double iconSize = 18;
  static const double providerIconWidth = 18;
  static const double providerIconHeight = 18;
  static const double providerGlyphSize = 18;
  static const double labelFontSize = 12;
  static const FontWeight labelFontWeight = FontWeight.w800;
  static const double maximumTextScale = 1.3;
  static const double selectedIndicatorWidth = 12;
  static const double selectedIndicatorHeight = 2;
  static const Duration pressDuration = Duration(milliseconds: 100);
  static const Duration stateDuration = MoolMotion.quick;
  static const Duration selectionDuration = Duration(milliseconds: 180);
  static const Duration disclosureDuration = Duration(milliseconds: 180);
  static const double disclosureBadgeSize = 18;
  static const double disclosureBadgeIconSize = 14;
  static const double connectionLineStrokeWidth = 1.25;
  static const double connectionLineMaximumOpacity = .24;
  static const double connectionDotRadius = 1.5;
  static const double destinationFixedCellWidth = 54;
  static const double destinationMinimumFixedCellWidth = 44;
  static const double destinationCompactWidthBreakpoint = 340;

  static double destinationFixedCellWidthFor(double viewportWidth) =>
      viewportWidth <= destinationCompactWidthBreakpoint
      ? destinationMinimumFixedCellWidth
      : destinationFixedCellWidth;

  static const double destinationPreferredLocalCellWidth = 72;
  static const double destinationItemGap = MoolSpacing.xs;
  static const double destinationCompactItemGap = 2;
  static const double destinationIconSize = 22;
  static const double destinationLabelSize = 10.5;
  static const double destinationLabelLineHeight = 1;
  static const double destinationLabelSlotHeight = 28;
  static const String destinationFontFamily = 'Inter';
  static const FontWeight destinationLabelWeight = FontWeight.w700;
  static const FontWeight destinationSelectedLabelWeight = FontWeight.w800;
  static const double destinationSelectedIndicatorWidth = 14;
  static const double destinationSelectedIndicatorHeight = 2;
  static const double destinationSelectedCellRadius = 14;
  static const double destinationSelectedFillOpacity = .10;
  static const double destinationSelectedBorderOpacity = .22;
  static const Color destinationCanvas = Color(0xF7F8F9FC);
  static const Color destinationDivider = Color(0x1F12163D);
  static const double switcherWidth = 136;
  static const double switcherRadius = 16;
  static const double switcherRowRadius = 12;
  static const double switcherRowHeight = 56;
  static const double switcherPadding = 4;
  static const double switcherRowHorizontalPadding = 8;
  static const double switcherIconContainerSize = 30;
  static const double switcherIconSize = destinationIconSize;
  static const double switcherSelectedIndicatorWidth = 2;
  static const double switcherSelectedIndicatorHeight = 18;
  static const double switcherBlurSigma = 20;
  static const double switcherShadowBlurRadius = 24;
  static const Offset switcherShadowOffset = Offset(0, 12);
  static const Color switcherCanvas = Color(0xD9FFFFFF);
  static const Color switcherBorder = Color(0xCCFFFFFF);
  static const Color switcherIconBorder = Color(0xA6FFFFFF);
  static const Color switcherShadow = Color(0x20181B43);
  static const double switcherSelectedFillOpacity = .10;
  static const double switcherSelectedIconFillOpacity = .16;
  static const double switcherIconFillOpacity = .09;
  static const Color neutralGlassTop = Color(0xE8FFFFFF);
  static const Color neutralGlassBottom = Color(0xD8F4F6FB);
  static const Color neutralForeground = MoolColors.navy;
  static const Color lightForeground = neutralForeground;
  static const Color mediaForeground = neutralForeground;
  static const double minimumNeutralDestinationTransmission = .29;
  static const double minimumWhiteForegroundContrast = 4.5;
  static const double maximumInnerEmissionAlpha = .28;
  static const double innerEmissionCenterAlpha = .27;
  static const double innerEmissionMiddleAlpha = .135;
  static const double pressedEmissionOpacity = .62;

  static MoolLocalNavigationSurfaceTone surfaceToneForFamily(String familyId) =>
      MoolLocalNavigationSurfaceTone.media;

  static Color selectionColor(MoolLocalNavigationSurfaceTone tone) =>
      MoolColors.royal;

  static Color selectionColorForFamily(String familyId) =>
      selectionColor(surfaceToneForFamily(familyId));

  static Color emissionColorForFamily(String familyId) => switch (familyId) {
    'social' => const Color(0xFF7C5CFF),
    'buy' => const Color(0xFFFFB347),
    'eat' => const Color(0xFFFF6B7A),
    'ride' => const Color(0xFF41C7FF),
    'book' => const Color(0xFF3DDC97),
    'work' => const Color(0xFF6EA8FF),
    _ => MoolColors.royal,
  };

  static Color navigationAccentForFamily(String familyId) => switch (familyId) {
    'social' => const Color(0xFF3155C6),
    'buy' => const Color(0xFF7B3FB5),
    'eat' => const Color(0xFFC64E2B),
    'ride' => const Color(0xFF087E9A),
    'book' => const Color(0xFF16825D),
    'work' => const Color(0xFF9A6400),
    _ => MoolColors.navy,
  };

  static RadialGradient innerEmissionGradient(String familyId) {
    final accent = emissionColorForFamily(familyId);
    return RadialGradient(
      center: const Alignment(0, .42),
      radius: .92,
      colors: [
        accent.withValues(alpha: innerEmissionCenterAlpha),
        accent.withValues(alpha: innerEmissionMiddleAlpha),
        accent.withValues(alpha: 0),
      ],
      stops: const [0, .48, 1],
    );
  }

  static Color foreground(MoolLocalNavigationSurfaceTone tone) =>
      neutralForeground;

  static LinearGradient glassGradient({
    required MoolLocalNavigationSurfaceTone tone,
    required bool selected,
    required bool pressed,
  }) {
    const top = neutralGlassTop;
    const bottom = neutralGlassBottom;
    final stateAlpha = (selected ? .035 : 0) + (pressed ? .045 : 0);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        top.withValues(alpha: (top.a + stateAlpha).clamp(0.0, 1.0)),
        bottom.withValues(alpha: (bottom.a + stateAlpha).clamp(0.0, 1.0)),
      ],
    );
  }

  static LinearGradient specularGradient(MoolLocalNavigationSurfaceTone tone) =>
      LinearGradient(
        colors: [
          Colors.white.withValues(alpha: .92),
          Colors.white.withValues(alpha: .30),
          Colors.white.withValues(alpha: 0),
        ],
      );

  static List<BoxShadow> controlShadows({
    required MoolLocalNavigationSurfaceTone tone,
    required bool selected,
    required bool pressed,
  }) {
    return [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: pressed ? .07 : (selected ? .12 : .06),
        ),
        blurRadius: pressed ? 6 : (selected ? 12 : 8),
        offset: Offset(0, pressed ? 1 : (selected ? 4 : 2)),
      ),
    ];
  }

  static Color borderColor({
    required MoolLocalNavigationSurfaceTone tone,
    required bool selected,
    required bool pressed,
  }) {
    if (selected) return MoolColors.royal.withValues(alpha: .28);
    if (pressed) return MoolColors.navy.withValues(alpha: .18);
    return MoolColors.navy.withValues(alpha: .10);
  }

  static Color pressedOverlay(MoolLocalNavigationSurfaceTone tone) =>
      MoolColors.royal.withValues(alpha: .07);

  static double preferredCellWidth(int actionCount) => capsuleWidth;

  static double gap(double maxWidth, int actionCount) {
    final preferred =
        destinationPreferredLocalCellWidth * actionCount +
        destinationItemGap * math.max(0, actionCount - 1);
    return preferred <= maxWidth
        ? destinationItemGap
        : destinationCompactItemGap;
  }

  static double clusterWidth(double maxWidth, int actionCount) {
    assert(actionCount > 0);
    final insetAvailable = math.max(0.0, maxWidth - horizontalInset * 2);
    final resolvedGap = gap(insetAvailable, actionCount);
    final gaps = resolvedGap * math.max(0, actionCount - 1);
    final preferred = destinationPreferredLocalCellWidth * actionCount + gaps;
    final minimum = MoolMetrics.minimumTapTarget * actionCount + gaps;
    assert(
      minimum <= insetAvailable,
      'Local navigation requires at least $minimum logical pixels.',
    );
    return math.min(preferred, insetAvailable);
  }

  static double cellWidth(double maxWidth, int actionCount) {
    final width = clusterWidth(maxWidth, actionCount);
    final gaps = gap(width, actionCount) * math.max(0, actionCount - 1);
    return (width - gaps) / actionCount;
  }

  static double selectedCenterX({
    required double maxWidth,
    required int actionCount,
    required double selectedIndex,
  }) {
    assert(actionCount > 0);
    final width = clusterWidth(maxWidth, actionCount);
    final cell = cellWidth(maxWidth, actionCount);
    final resolvedGap = gap(width, actionCount);
    final index = selectedIndex.clamp(0.0, actionCount - 1.0);
    final left = (maxWidth - width) / 2;
    return left + index * (cell + resolvedGap) + cell / 2;
  }
}

@immutable
class MoolHomeHubAction {
  const MoolHomeHubAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

/// C23 Home-hub geometry is deliberately separate from the rejected rail
/// geometry. It is used only inside the existing Mool Home destination.
abstract final class MoolHomeHubTokens {
  static const double familyRowRadius = 22;
  static const double familyRowPadding = MoolSpacing.sm;
  static const double familyGap = MoolSpacing.xs;
  static const double mainActionHeight = 56;
  static const double mainActionWidth = 112;
  static const double subactionHeight = MoolMetrics.minimumTapTarget;
  static const double subactionMinimumWidth = 92;
  static const double actionGap = MoolSpacing.xs;
  static const double mainIconSize = 21;
  static const double subactionIconSize = 17;
  static const double mainLabelSize = 13;
  static const double subactionLabelSize = 11.5;
  static const FontWeight mainLabelWeight = FontWeight.w900;
  static const FontWeight subactionLabelWeight = FontWeight.w800;
  static const Duration arrivalDuration = Duration(milliseconds: 220);
  static const Duration pressDuration = Duration(milliseconds: 100);
  static const Color surface = Color(0xF2FFFFFF);
  static const Color foreground = MoolColors.navy;
  static const Color secondaryForeground = Color(0xFF4D5367);
  static const Color border = Color(0x1F000080);

  static Color accentForFamily(String familyId) =>
      MoolLocalNavigationTokens.emissionColorForFamily(familyId);

  static Duration accessibleDuration(BuildContext context, Duration duration) {
    final media = MediaQuery.of(context);
    return media.disableAnimations || media.accessibleNavigation
        ? Duration.zero
        : duration;
  }
}

/// A vertically composed family owner for Mool Home. It never scrolls actions
/// horizontally and never requires an expansion tap before a subaction.
class MoolHomeHubFamilyRow extends StatelessWidget {
  const MoolHomeHubFamilyRow({
    required this.familyId,
    required this.label,
    required this.icon,
    required this.onOpenFamily,
    required this.actions,
    super.key,
  }) : assert(actions.length > 0);

  final String familyId;
  final String label;
  final IconData icon;
  final VoidCallback onOpenFamily;
  final List<MoolHomeHubAction> actions;

  @override
  Widget build(BuildContext context) {
    final accent = MoolHomeHubTokens.accentForFamily(familyId);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$label services',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MoolHomeHubTokens.surface,
              accent.withValues(alpha: .055),
              MoolHomeHubTokens.surface,
            ],
            stops: const [0, .58, 1],
          ),
          borderRadius: BorderRadius.circular(
            MoolHomeHubTokens.familyRowRadius,
          ),
          border: Border.all(color: MoolHomeHubTokens.border),
          boxShadow: MoolShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(MoolHomeHubTokens.familyRowPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 330 || textScale > 1.2;
              final main = _MoolHomeHubButton(
                key: ValueKey('mool-home-family-$familyId'),
                label: label,
                icon: icon,
                accent: accent,
                primary: true,
                onPressed: onOpenFamily,
              );
              final subactions = _MoolHomeHubActionGrid(
                familyId: familyId,
                actions: actions,
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    main,
                    const SizedBox(height: MoolHomeHubTokens.familyGap),
                    subactions,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MoolHomeHubTokens.mainActionWidth,
                    child: main,
                  ),
                  const SizedBox(width: MoolHomeHubTokens.familyGap),
                  Expanded(child: subactions),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MoolHomeHubActionGrid extends StatelessWidget {
  const _MoolHomeHubActionGrid({required this.familyId, required this.actions});

  final String familyId;
  final List<MoolHomeHubAction> actions;

  @override
  Widget build(BuildContext context) {
    final accent = MoolHomeHubTokens.accentForFamily(familyId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >=
                MoolHomeHubTokens.subactionMinimumWidth * 2 +
                    MoolHomeHubTokens.actionGap
            ? 2
            : 1;
        final width = columns == 2
            ? (constraints.maxWidth - MoolHomeHubTokens.actionGap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: MoolHomeHubTokens.actionGap,
          runSpacing: MoolHomeHubTokens.actionGap,
          children: [
            for (final action in actions)
              SizedBox(
                width: width,
                child: _MoolHomeHubButton(
                  key: ValueKey('mool-home-$familyId-${action.id}'),
                  label: action.label,
                  icon: action.icon,
                  accent: accent,
                  onPressed: action.onPressed,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MoolHomeHubButton extends StatefulWidget {
  const _MoolHomeHubButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
    this.primary = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;
  final bool primary;

  @override
  State<_MoolHomeHubButton> createState() => _MoolHomeHubButtonState();
}

class _MoolHomeHubButtonState extends State<_MoolHomeHubButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.primary ? 18 : 16);
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? .975 : 1,
        duration: MoolHomeHubTokens.accessibleDuration(
          context,
          MoolHomeHubTokens.pressDuration,
        ),
        curve: MoolMotion.change,
        child: AnimatedContainer(
          duration: MoolHomeHubTokens.accessibleDuration(
            context,
            MoolHomeHubTokens.pressDuration,
          ),
          constraints: BoxConstraints(
            minHeight: widget.primary
                ? MoolHomeHubTokens.mainActionHeight
                : MoolHomeHubTokens.subactionHeight,
          ),
          decoration: BoxDecoration(
            gradient: widget.primary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accent.withValues(alpha: _pressed ? .30 : .20),
                      Colors.white.withValues(alpha: .92),
                    ],
                  )
                : null,
            color: widget.primary ? null : Colors.white.withValues(alpha: .82),
            borderRadius: radius,
            border: Border.all(
              color: widget.primary
                  ? widget.accent.withValues(alpha: .42)
                  : MoolHomeHubTokens.border,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onHighlightChanged: (pressed) {
                if (_pressed != pressed) setState(() => _pressed = pressed);
              },
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.primary ? MoolSpacing.sm : MoolSpacing.xs,
                  vertical: MoolSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      size: widget.primary
                          ? MoolHomeHubTokens.mainIconSize
                          : MoolHomeHubTokens.subactionIconSize,
                      color: MoolHomeHubTokens.foreground,
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.primary
                              ? MoolHomeHubTokens.foreground
                              : MoolHomeHubTokens.secondaryForeground,
                          fontSize: widget.primary
                              ? MoolHomeHubTokens.mainLabelSize
                              : MoolHomeHubTokens.subactionLabelSize,
                          height: 1.1,
                          fontWeight: widget.primary
                              ? MoolHomeHubTokens.mainLabelWeight
                              : MoolHomeHubTokens.subactionLabelWeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolInnerChromaEmission extends StatelessWidget {
  const _MoolInnerChromaEmission({
    required this.keyPrefix,
    required this.familyId,
    required this.selected,
    required this.pressed,
  });

  final String keyPrefix;
  final String familyId;
  final bool selected;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final gradient = MoolLocalNavigationTokens.innerEmissionGradient(familyId);
    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedOpacity(
                key: ValueKey('$keyPrefix-selected-inner-chroma'),
                opacity: selected ? 1 : 0,
                duration: MoolMotion.accessible(
                  context,
                  MoolLocalNavigationTokens.selectionDuration,
                ),
                curve: MoolMotion.change,
                child: DecoratedBox(
                  key: ValueKey('$keyPrefix-selected-inner-chroma-source'),
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
              AnimatedOpacity(
                key: ValueKey('$keyPrefix-pressed-inner-chroma'),
                opacity: pressed
                    ? MoolLocalNavigationTokens.pressedEmissionOpacity
                    : 0,
                duration: MoolMotion.accessible(
                  context,
                  MoolLocalNavigationTokens.pressDuration,
                ),
                curve: MoolMotion.change,
                child: DecoratedBox(
                  key: ValueKey('$keyPrefix-pressed-inner-chroma-source'),
                  decoration: BoxDecoration(gradient: gradient),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One fixed icon-and-label optical owner for Mool, family context and every
/// destination-local action.
class MoolDestinationIconLabel extends StatelessWidget {
  const MoolDestinationIconLabel({
    required this.label,
    required this.icon,
    required this.color,
    required this.emphasized,
    this.iconAsset,
    super.key,
  });

  final String label;
  final IconData icon;
  final String? iconAsset;
  final Color color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, MoolLocalNavigationTokens.maximumTextScale);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: MoolLocalNavigationTokens.destinationIconSize,
            height: MoolLocalNavigationTokens.destinationIconSize,
            child: Center(
              child: iconAsset == null
                  ? Icon(
                      icon,
                      size: MoolLocalNavigationTokens.destinationIconSize,
                      color: color,
                    )
                  : SvgPicture.asset(
                      iconAsset!,
                      width: MoolLocalNavigationTokens.providerGlyphSize,
                      height: MoolLocalNavigationTokens.providerGlyphSize,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: MoolLocalNavigationTokens.destinationLabelSlotHeight,
            child: Center(
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontFamily: MoolLocalNavigationTokens.destinationFontFamily,
                    fontSize: MoolLocalNavigationTokens.destinationLabelSize,
                    height:
                        MoolLocalNavigationTokens.destinationLabelLineHeight,
                    fontWeight: emphasized
                        ? MoolLocalNavigationTokens
                              .destinationSelectedLabelWeight
                        : MoolLocalNavigationTokens.destinationLabelWeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Destination-local choices live inside content and never replace the one
/// global bottom-navigation meaning.
class MoolLocalNavigationRail extends StatelessWidget {
  const MoolLocalNavigationRail({
    required this.familyId,
    required this.semanticLabel,
    required this.activeId,
    required this.actions,
    this.surfaceTone = MoolLocalNavigationSurfaceTone.light,
    super.key,
  }) : assert(actions.length > 0);

  final String familyId;
  final String semanticLabel;
  final String activeId;
  final List<MoolLocalNavigationAction> actions;
  final MoolLocalNavigationSurfaceTone surfaceTone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: SizedBox(
        height: MoolLocalNavigationTokens.destinationRailHeight,
        child: LayoutBuilder(
          key: const Key('moolsocial-local-navigation-adaptive-layout'),
          builder: (context, constraints) {
            final minimumClusterWidth =
                MoolMetrics.minimumTapTarget * actions.length;
            final requiresOverflow = minimumClusterWidth > constraints.maxWidth;
            final clusterWidth = requiresOverflow
                ? minimumClusterWidth
                : constraints.maxWidth;
            final cellWidth = requiresOverflow
                ? MoolMetrics.minimumTapTarget
                : constraints.maxWidth / actions.length;
            final cluster = SizedBox(
              key: const Key('moolsocial-local-navigation-compact-cluster'),
              width: clusterWidth,
              height: MoolLocalNavigationTokens.destinationRailHeight,
              child: Row(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    SizedBox(
                      width: cellWidth,
                      height: MoolLocalNavigationTokens.destinationRailHeight,
                      child: _MoolLocalNavigationCell(
                        familyId: familyId,
                        action: actions[index],
                        selected: activeId == actions[index].id,
                      ),
                    ),
                  ],
                ],
              ),
            );
            return Align(
              alignment: Alignment.centerLeft,
              child: requiresOverflow
                  ? SingleChildScrollView(
                      key: const Key(
                        'moolsocial-local-navigation-compact-overflow',
                      ),
                      scrollDirection: Axis.horizontal,
                      child: cluster,
                    )
                  : cluster,
            );
          },
        ),
      ),
    );
  }
}

class _MoolLocalNavigationCell extends StatefulWidget {
  const _MoolLocalNavigationCell({
    required this.familyId,
    required this.action,
    required this.selected,
  });

  final String familyId;
  final MoolLocalNavigationAction action;
  final bool selected;

  @override
  State<_MoolLocalNavigationCell> createState() =>
      _MoolLocalNavigationCellState();
}

class _MoolLocalNavigationCellState extends State<_MoolLocalNavigationCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final selected = widget.selected;
    final accent = MoolLocalNavigationTokens.navigationAccentForFamily(
      widget.familyId,
    );
    final foreground = selected ? accent : MoolColors.muted;
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      enabled: action.onPressed != null,
      onTap: action.onPressed,
      label: selected
          ? '${action.semanticLabel ?? action.label}, current'
          : 'Open ${action.semanticLabel ?? action.label}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: selected
              ? '${action.semanticLabel ?? action.label}, current'
              : 'Open ${action.semanticLabel ?? action.label}',
          child: AnimatedScale(
            key: ValueKey('moolsocial-local-${action.id}-pressed-scale'),
            scale: _pressed ? .975 : 1,
            duration: MoolMotion.accessible(
              context,
              MoolLocalNavigationTokens.pressDuration,
            ),
            curve: MoolMotion.change,
            child: AnimatedContainer(
              key: ValueKey('moolsocial-local-${action.id}-selection'),
              duration: MoolMotion.accessible(
                context,
                MoolLocalNavigationTokens.stateDuration,
              ),
              curve: MoolMotion.change,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(
                        alpha: MoolLocalNavigationTokens
                            .destinationSelectedFillOpacity,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  MoolLocalNavigationTokens.destinationSelectedCellRadius,
                ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  MoolLocalNavigationTokens.destinationSelectedCellRadius,
                ),
                border: Border.all(
                  color: selected
                      ? accent.withValues(
                          alpha: MoolLocalNavigationTokens
                              .destinationSelectedBorderOpacity,
                        )
                      : Colors.transparent,
                ),
              ),
              child: InkWell(
                key: Key(action.keyName),
                onTap: action.onPressed,
                onHighlightChanged: action.onPressed == null
                    ? null
                    : (value) => setState(() => _pressed = value),
                borderRadius: BorderRadius.circular(
                  MoolLocalNavigationTokens.destinationSelectedCellRadius,
                ),
                splashColor: accent.withValues(alpha: .08),
                highlightColor: accent.withValues(alpha: .045),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ExcludeSemantics(
                      child: MoolDestinationIconLabel(
                        key: ValueKey(
                          'moolsocial-local-${action.id}-icon-label',
                        ),
                        label: action.label,
                        icon: action.icon,
                        iconAsset: action.iconAsset,
                        color: foreground,
                        emphasized: selected,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: AnimatedContainer(
                        key: ValueKey(
                          'moolsocial-local-${action.id}-selected-indicator',
                        ),
                        duration: MoolMotion.accessible(
                          context,
                          MoolLocalNavigationTokens.stateDuration,
                        ),
                        curve: MoolMotion.change,
                        width: selected
                            ? MoolLocalNavigationTokens
                                  .destinationSelectedIndicatorWidth
                            : 0,
                        height: MoolLocalNavigationTokens
                            .destinationSelectedIndicatorHeight,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One persistent navigation language for every product vertical: Mool and
/// Chat remain stable while the current vertical owns a readable middle rail.
class MoolOutcomeDock extends StatelessWidget {
  const MoolOutcomeDock({
    required this.semanticLabel,
    required this.activeId,
    required this.mool,
    required this.actions,
    required this.chat,
    this.actionsKey,
    this.showOverflowCue = false,
    super.key,
  });

  final String semanticLabel;
  final String activeId;
  final MoolDockAction mool;
  final List<MoolDockAction> actions;
  final MoolDockAction chat;
  final Key? actionsKey;
  final bool showOverflowCue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        key: const Key('mool-outcome-dock-surface'),
        height: MoolLocalNavigationTokens.destinationRailHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: MoolLocalNavigationTokens.destinationCanvas,
            border: Border(
              top: BorderSide(
                color: MoolLocalNavigationTokens.destinationDivider,
              ),
            ),
          ),
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: semanticLabel,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellCount = actions.length + 2;
                final minimumWidth = MoolMetrics.minimumTapTarget * cellCount;
                final overflow = minimumWidth > constraints.maxWidth;
                final cellWidth = overflow
                    ? MoolMetrics.minimumTapTarget
                    : constraints.maxWidth / cellCount;
                final cells = <Widget>[
                  _MoolEdgeDockAction(
                    action: mool,
                    selected: activeId == mool.id,
                    isMool: true,
                  ),
                  for (final action in actions)
                    _MoolMiddleDockAction(
                      action: action,
                      selected: activeId == action.id,
                    ),
                  _MoolEdgeDockAction(
                    action: chat,
                    selected: activeId == chat.id,
                  ),
                ];
                final row = KeyedSubtree(
                  key: actionsKey,
                  child: SizedBox(
                    width: overflow ? minimumWidth : constraints.maxWidth,
                    height: MoolLocalNavigationTokens.destinationRailHeight,
                    child: Row(
                      children: [
                        for (final cell in cells)
                          SizedBox(
                            width: cellWidth,
                            height:
                                MoolLocalNavigationTokens.destinationRailHeight,
                            child: cell,
                          ),
                      ],
                    ),
                  ),
                );
                if (!overflow) return row;
                return SingleChildScrollView(
                  key: const Key('mool-outcome-dock-overflow'),
                  scrollDirection: Axis.horizontal,
                  child: row,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolScrollableDockActions extends StatefulWidget {
  const _MoolScrollableDockActions({
    required this.actions,
    required this.activeId,
  });

  final List<MoolDockAction> actions;
  final String activeId;

  @override
  State<_MoolScrollableDockActions> createState() =>
      _MoolScrollableDockActionsState();
}

class _MoolScrollableDockActionsState
    extends State<_MoolScrollableDockActions> {
  late final ScrollController _controller = ScrollController()
    ..addListener(_syncCues);
  bool _canScrollBack = false;
  bool _canScrollForward = false;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleCueSync();
  }

  @override
  void didUpdateWidget(covariant _MoolScrollableDockActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCueSync();
  }

  void _scheduleCueSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _revealActiveAction();
      _syncCues();
    });
  }

  void _revealActiveAction() {
    if (!_controller.hasClients) return;
    final activeIndex = widget.actions.indexWhere(
      (action) => action.id == widget.activeId,
    );
    if (activeIndex < 0) return;
    final position = _controller.position;
    final target =
        (activeIndex *
                    (MoolLocalNavigationTokens.capsuleWidth +
                        MoolLocalNavigationTokens.itemGap) -
                MoolLocalNavigationTokens.itemGap)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 1) return;
    if (_reduceMotion) {
      _controller.jumpTo(target);
      _syncCues();
      return;
    }
    _controller
        .animateTo(target, duration: MoolMotion.quick, curve: MoolMotion.enter)
        .whenComplete(() {
          if (mounted) _syncCues();
        });
  }

  bool get _reduceMotion {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 1) return;
    HapticFeedback.selectionClick();
    if (_reduceMotion) {
      _controller.jumpTo(target);
      _syncCues();
      return;
    }
    _controller
        .animateTo(target, duration: MoolMotion.quick, curve: MoolMotion.enter)
        .whenComplete(() {
          if (mounted) _syncCues();
        });
  }

  void _syncCues() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final nextBack = position.pixels > 1;
    final nextForward = position.pixels < position.maxScrollExtent - 1;
    if (nextBack == _canScrollBack && nextForward == _canScrollForward) {
      return;
    }
    setState(() {
      _canScrollBack = nextBack;
      _canScrollForward = nextForward;
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncCues)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cueDuration = MoolMotion.accessible(context, MoolMotion.quick);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label:
          'More MoolSocial options. Swipe horizontally to explore all ${widget.actions.length}.',
      child: Row(
        children: [
          SizedBox(
            width: MoolMetrics.minimumTapTarget,
            child: AnimatedOpacity(
              key: const Key('mool-main-rail-overflow-back'),
              duration: cueDuration,
              opacity: _canScrollBack ? 1 : 0,
              child: ExcludeSemantics(
                excluding: !_canScrollBack,
                child: IgnorePointer(
                  ignoring: !_canScrollBack,
                  child: _MoolRailOverflowCue(
                    icon: Icons.chevron_left_rounded,
                    semanticLabel: 'Previous main actions',
                    onPressed: () => _scrollBy(
                      -(MoolLocalNavigationTokens.capsuleWidth +
                          MoolLocalNavigationTokens.itemGap),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('mool-scrollable-dock-actions'),
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  for (
                    var index = 0;
                    index < widget.actions.length;
                    index++
                  ) ...[
                    if (index > 0)
                      const SizedBox(width: MoolLocalNavigationTokens.itemGap),
                    SizedBox(
                      width: MoolLocalNavigationTokens.capsuleWidth,
                      child: _MoolMiddleDockAction(
                        action: widget.actions[index],
                        selected: widget.activeId == widget.actions[index].id,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            width: MoolMetrics.minimumTapTarget,
            child: AnimatedOpacity(
              key: const Key('mool-main-rail-overflow-cue'),
              duration: cueDuration,
              opacity: _canScrollForward ? 1 : 0,
              child: ExcludeSemantics(
                excluding: !_canScrollForward,
                child: IgnorePointer(
                  ignoring: !_canScrollForward,
                  child: _MoolRailOverflowCue(
                    icon: Icons.chevron_right_rounded,
                    semanticLabel: 'Next main actions',
                    onPressed: () => _scrollBy(
                      MoolLocalNavigationTokens.capsuleWidth +
                          MoolLocalNavigationTokens.itemGap,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoolRailOverflowCue extends StatelessWidget {
  const _MoolRailOverflowCue({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(MoolRadii.control),
            child: Container(
              width: MoolMetrics.minimumTapTarget,
              height: MoolMetrics.compactTapTarget,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x00F0F1F8), Color(0xFFF0F1F8)],
                ),
              ),
              child: Icon(icon, size: 20, color: MoolColors.navy),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolEdgeDockAction extends StatelessWidget {
  const _MoolEdgeDockAction({
    required this.action,
    required this.selected,
    this.isMool = false,
  });

  final MoolDockAction action;
  final bool selected;
  final bool isMool;

  @override
  Widget build(BuildContext context) {
    final foreground = selected || isMool ? Colors.white : MoolColors.navy;
    return Semantics(
      key: action.anchorKey,
      selected: selected,
      button: true,
      enabled: action.onPressed != null,
      label: selected
          ? '${action.semanticLabel ?? action.label}, current'
          : action.semanticLabel ?? 'Open ${action.label}',
      onTap: action.onPressed,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key(action.keyName),
          onTap: action.onPressed,
          borderRadius: BorderRadius.circular(
            MoolLocalNavigationTokens.destinationSelectedCellRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: AnimatedContainer(
              duration: MoolMotion.accessible(context, MoolMotion.quick),
              curve: MoolMotion.change,
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: isMool
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2929D4), Color(0xFF07076E)],
                      )
                    : null,
                color: isMool
                    ? null
                    : selected
                    ? MoolColors.navy
                    : Colors.white.withValues(alpha: .74),
                borderRadius: BorderRadius.circular(
                  MoolLocalNavigationTokens.destinationSelectedCellRadius,
                ),
                border: Border.all(
                  color: selected || isMool
                      ? Colors.white.withValues(alpha: .22)
                      : const Color(0x16000080),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: isMool
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  MoolBrand.moolLauncherIcon,
                                  color: Colors.white,
                                  size: 19,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Mool',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(action.icon, color: foreground, size: 19),
                                const SizedBox(height: 2),
                                Text(
                                  action.label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (action.badgeCount > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        height: 18,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: MoolColors.orange,
                          borderRadius: BorderRadius.circular(
                            MoolRadii.capsule,
                          ),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${action.badgeCount}',
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolMiddleDockAction extends StatefulWidget {
  const _MoolMiddleDockAction({required this.action, required this.selected});

  final MoolDockAction action;
  final bool selected;

  @override
  State<_MoolMiddleDockAction> createState() => _MoolMiddleDockActionState();
}

class _MoolMiddleDockActionState extends State<_MoolMiddleDockAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final selected = widget.selected;
    final radius = BorderRadius.circular(
      MoolLocalNavigationTokens.destinationSelectedCellRadius,
    );
    return Semantics(
      key: action.anchorKey,
      selected: selected,
      button: true,
      enabled: action.onPressed != null,
      label: selected
          ? '${action.semanticLabel ?? action.label}, current'
          : 'Open ${action.semanticLabel ?? action.label}',
      onTap: action.onPressed,
      excludeSemantics: true,
      child: SizedBox(
        height: MoolLocalNavigationTokens.destinationRailHeight,
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: MoolLocalNavigationTokens.backdropBlurSigma,
              sigmaY: MoolLocalNavigationTokens.backdropBlurSigma,
            ),
            child: AnimatedContainer(
              key: ValueKey('mool-action-${action.id}-capsule'),
              duration: MoolMotion.accessible(context, MoolMotion.quick),
              curve: MoolMotion.change,
              decoration: BoxDecoration(
                gradient: MoolLocalNavigationTokens.glassGradient(
                  tone: MoolLocalNavigationSurfaceTone.media,
                  selected: selected,
                  pressed: _pressed,
                ),
                borderRadius: radius,
                boxShadow: MoolLocalNavigationTokens.controlShadows(
                  tone: MoolLocalNavigationSurfaceTone.media,
                  selected: selected,
                  pressed: _pressed,
                ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: MoolLocalNavigationTokens.borderColor(
                    tone: MoolLocalNavigationSurfaceTone.media,
                    selected: selected,
                    pressed: _pressed,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key(action.keyName),
                  onTap: action.onPressed,
                  onHighlightChanged: action.onPressed == null
                      ? null
                      : (value) => setState(() => _pressed = value),
                  borderRadius: radius,
                  splashColor: MoolLocalNavigationTokens.pressedOverlay(
                    MoolLocalNavigationSurfaceTone.media,
                  ),
                  highlightColor: MoolLocalNavigationTokens.pressedOverlay(
                    MoolLocalNavigationSurfaceTone.media,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _MoolInnerChromaEmission(
                        keyPrefix: 'mool-action-${action.id}',
                        familyId: action.id,
                        selected: selected,
                        pressed: _pressed,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              action.icon,
                              size: MoolLocalNavigationTokens.iconSize,
                              color: selected
                                  ? MoolColors.royal
                                  : MoolLocalNavigationTokens.neutralForeground,
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                action.label,
                                maxLines: 1,
                                style: TextStyle(
                                  color: selected
                                      ? MoolColors.royal
                                      : MoolLocalNavigationTokens
                                            .neutralForeground,
                                  fontSize:
                                      MoolLocalNavigationTokens.labelFontSize,
                                  height: 1.05,
                                  fontWeight: selected
                                      ? FontWeight.w900
                                      : MoolLocalNavigationTokens
                                            .labelFontWeight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected && action.disclosureExpanded != null)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: AnimatedContainer(
                            key: ValueKey(
                              'mool-action-${action.id}-subaction-disclosure-badge',
                            ),
                            duration: MoolMotion.accessible(
                              context,
                              MoolLocalNavigationTokens.stateDuration,
                            ),
                            width:
                                MoolLocalNavigationTokens.disclosureBadgeSize,
                            height:
                                MoolLocalNavigationTokens.disclosureBadgeSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: .32),
                                  Colors.white.withValues(alpha: .12),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .58),
                              ),
                            ),
                            child: Icon(
                              action.disclosureExpanded!
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              size: MoolLocalNavigationTokens
                                  .disclosureBadgeIconSize,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 1,
                        left: 12,
                        right: 12,
                        height: 1,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient:
                                  MoolLocalNavigationTokens.specularGradient(
                                    MoolLocalNavigationSurfaceTone.media,
                                  ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 1,
                        height: MoolLocalNavigationTokens
                            .destinationSelectedIndicatorHeight,
                        child: AnimatedOpacity(
                          key: ValueKey(
                            'mool-action-${action.id}-selected-indicator',
                          ),
                          opacity: selected ? 1 : 0,
                          duration: MoolMotion.accessible(
                            context,
                            MoolLocalNavigationTokens.stateDuration,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: MoolColors.royal,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
