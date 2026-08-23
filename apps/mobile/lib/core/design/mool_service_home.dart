import 'package:flutter/material.dart';

import 'mool_design_system.dart';
import 'mool_theme.dart';

/// Shared native-Flutter hierarchy for customer-facing service discovery.
abstract final class MoolServiceHomeTokens {
  static const double pagePadding = MoolSpacing.md;
  static const double sectionGap = MoolSpacing.lg;
  static const double cardGap = MoolSpacing.sm;
  static const double cardRadius = 18;
  static const double searchHeight = 52;
  static const double primaryActionHeight = 48;

  static const double displaySize = 28;
  static const double sectionTitleSize = 20;
  static const double cardTitleSize = 16;
  static const double bodySize = 14;
  static const double metadataSize = 12;

  static const Color page = Color(0xFFF6F8FC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E7F0);
  static const Color ink = MoolColors.ink;
  static const Color muted = MoolColors.muted;

  static const Duration changeDuration = Duration(milliseconds: 220);

  static Duration accessibleDuration(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media?.disableAnimations ?? false) return Duration.zero;
    if (media?.accessibleNavigation ?? false) return Duration.zero;
    return changeDuration;
  }
}

class MoolServiceSearchField extends StatelessWidget {
  const MoolServiceSearchField({
    required this.hintText,
    this.controller,
    this.focusNode,
    this.fieldKey,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.leading = Icons.search_rounded,
    this.trailing,
    this.semanticLabel,
    super.key,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final IconData leading;
  final Widget? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: MoolServiceHomeTokens.ink,
        fontSize: MoolServiceHomeTokens.bodySize,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: MoolServiceHomeTokens.muted,
          fontSize: MoolServiceHomeTokens.bodySize,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(leading, size: 21),
        suffixIcon: trailing,
        filled: true,
        fillColor: MoolServiceHomeTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MoolSpacing.md,
          vertical: MoolSpacing.sm,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoolRadii.card),
          borderSide: const BorderSide(color: MoolServiceHomeTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoolRadii.card),
          borderSide: const BorderSide(color: MoolColors.navy, width: 1.5),
        ),
      ),
    );
    return Semantics(
      textField: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: MoolServiceHomeTokens.searchHeight,
        ),
        child: field,
      ),
    );
  }
}

class MoolServiceSectionHeader extends StatelessWidget {
  const MoolServiceSectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null));

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: MoolServiceHomeTokens.ink,
                    fontSize: MoolServiceHomeTokens.sectionTitleSize,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: MoolServiceHomeTokens.muted,
                    fontSize: MoolServiceHomeTokens.metadataSize,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onAction != null) ...[
          const SizedBox(width: MoolSpacing.sm),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class MoolServiceChoice extends StatelessWidget {
  const MoolServiceChoice({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.accent = MoolColors.navy,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      avatar: icon == null ? null : Icon(icon, size: 17),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      side: BorderSide(
        color: selected
            ? accent.withValues(alpha: .52)
            : MoolServiceHomeTokens.border,
      ),
      selectedColor: accent.withValues(alpha: .12),
      backgroundColor: MoolServiceHomeTokens.surface,
      labelStyle: TextStyle(
        color: selected ? MoolServiceHomeTokens.ink : MoolColors.muted,
        fontSize: MoolServiceHomeTokens.metadataSize,
        fontWeight: FontWeight.w800,
      ),
      shape: const StadiumBorder(),
    );
  }
}

class MoolServiceMeta {
  const MoolServiceMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class MoolServiceCard extends StatefulWidget {
  const MoolServiceCard({
    required this.title,
    required this.subtitle,
    this.icon,
    this.accent = MoolColors.navy,
    this.metadata = const [],
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.emphasized = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final Color accent;
  final List<MoolServiceMeta> metadata;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool emphasized;

  @override
  State<MoolServiceCard> createState() => _MoolServiceCardState();
}

class _MoolServiceCardState extends State<MoolServiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(MoolServiceHomeTokens.cardRadius);
    final content = Padding(
      padding: const EdgeInsets.all(MoolSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(MoolRadii.control),
              ),
              child: Icon(widget.icon, color: widget.accent, size: 22),
            ),
            const SizedBox(width: MoolSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolServiceHomeTokens.ink,
                    fontSize: MoolServiceHomeTokens.cardTitleSize,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolServiceHomeTokens.muted,
                    fontSize: MoolServiceHomeTokens.bodySize,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.metadata.isNotEmpty) ...[
                  const SizedBox(height: MoolSpacing.sm),
                  Wrap(
                    spacing: MoolSpacing.sm,
                    runSpacing: MoolSpacing.xs,
                    children: [
                      for (final item in widget.metadata)
                        _ServiceMetadata(item: item),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: MoolSpacing.xs),
            widget.trailing!,
          ] else if (widget.onTap != null) ...[
            const SizedBox(width: MoolSpacing.xs),
            Icon(Icons.arrow_forward_rounded, color: widget.accent, size: 20),
          ],
        ],
      ),
    );
    final surface = AnimatedContainer(
      duration: MoolServiceHomeTokens.accessibleDuration(context),
      curve: MoolMotion.change,
      decoration: BoxDecoration(
        color: widget.emphasized
            ? widget.accent.withValues(alpha: _pressed ? .12 : .08)
            : MoolServiceHomeTokens.surface,
        borderRadius: radius,
        border: Border.all(
          color: widget.emphasized
              ? widget.accent.withValues(alpha: .32)
              : MoolServiceHomeTokens.border,
        ),
        boxShadow: _pressed ? const [] : MoolShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: widget.onTap == null
            ? content
            : InkWell(
                borderRadius: radius,
                onHighlightChanged: (value) {
                  if (_pressed != value) setState(() => _pressed = value);
                },
                onTap: widget.onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: MoolMetrics.minimumTapTarget,
                  ),
                  child: content,
                ),
              ),
      ),
    );
    if (widget.onTap == null) {
      return Semantics(container: true, child: surface);
    }
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? '${widget.title}. ${widget.subtitle}',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: surface,
    );
  }
}

class _ServiceMetadata extends StatelessWidget {
  const _ServiceMetadata({required this.item});

  final MoolServiceMeta item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 14, color: MoolServiceHomeTokens.muted),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            item.label,
            softWrap: true,
            style: const TextStyle(
              color: MoolServiceHomeTokens.muted,
              fontSize: MoolServiceHomeTokens.metadataSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class MoolServicePrimaryButton extends StatelessWidget {
  const MoolServicePrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.accent = MoolColors.navy,
    this.expand = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color accent;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: MoolColors.muted.withValues(alpha: .24),
        minimumSize: const Size(44, MoolServiceHomeTokens.primaryActionHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: MoolSpacing.md,
          vertical: MoolSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoolRadii.card),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: MoolServiceHomeTokens.bodySize,
          fontWeight: FontWeight.w900,
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 19),
      label: Text(label),
    );
    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
