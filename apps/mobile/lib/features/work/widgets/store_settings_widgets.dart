import 'package:flutter/material.dart';

import '../../../core/design/mool_colors.dart';

/// Local Store settings presentation; does not change the global app theme.
class StoreSettingsStyle extends StatelessWidget {
  const StoreSettingsStyle({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: MoolColors.navy,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xffe9ecff),
          onPrimaryContainer: MoolColors.navy,
          secondary: MoolColors.navy,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xffe9ecff),
          onSecondaryContainer: MoolColors.navy,
        ),
        chipTheme: theme.chipTheme.copyWith(checkmarkColor: Colors.white),
        timePickerTheme: theme.timePickerTheme.copyWith(
          dayPeriodColor: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xffe9ecff)
                : Colors.white,
          ),
          dayPeriodTextColor: MoolColors.navy,
        ),
        expansionTileTheme: theme.expansionTileTheme.copyWith(
          iconColor: MoolColors.navy,
          collapsedIconColor: MoolColors.navy,
          shape: const Border(
            top: BorderSide(color: MoolColors.line),
            bottom: BorderSide(color: MoolColors.line),
          ),
          collapsedShape: const Border(),
        ),
        textTheme: theme.textTheme.copyWith(
          titleLarge: theme.textTheme.titleLarge?.copyWith(
            letterSpacing: 0,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MoolColors.navy,
          ),
          titleMedium: theme.textTheme.titleMedium?.copyWith(
            letterSpacing: 0,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MoolColors.navy,
          ),
          bodyLarge: theme.textTheme.bodyLarge?.copyWith(
            letterSpacing: 0,
            fontSize: 14,
            color: MoolColors.ink,
          ),
          bodyMedium: theme.textTheme.bodyMedium?.copyWith(
            letterSpacing: 0,
            fontSize: 13,
            color: MoolColors.ink,
          ),
          bodySmall: theme.textTheme.bodySmall?.copyWith(
            letterSpacing: 0,
            fontSize: 12,
            color: MoolColors.muted,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          dense: true,
          minVerticalPadding: 0,
          minTileHeight: 48,
          horizontalTitleGap: 10,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
          iconColor: MoolColors.navy,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          labelStyle: const TextStyle(fontSize: 12, color: MoolColors.muted),
          errorMaxLines: 3,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MoolColors.line),
          ),
        ),
      ),
      child: child,
    );
  }
}

class StoreSettingsCard extends StatelessWidget {
  const StoreSettingsCard({required this.child, this.tonal = false, super.key});
  final Widget child;
  final bool tonal;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: tonal ? null : Colors.white,
      gradient: tonal
          ? const LinearGradient(colors: [Color(0xfff0f1ff), Colors.white])
          : null,
      border: Border.all(color: MoolColors.line),
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class StoreSettingsInput {
  const StoreSettingsInput({
    required this.id,
    required this.label,
    required this.controller,
    required this.validate,
    this.numeric = false,
    this.fullWidth = false,
    this.prefix,
    this.suffix,
    this.helper,
    this.maxLines = 1,
  });
  final String id, label;
  final TextEditingController controller;
  final String? Function(String?) validate;
  final bool numeric, fullWidth;
  final String? prefix, suffix, helper;
  final int maxLines;

  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter this detail.' : null;

  static String? pin(String? value) =>
      RegExp(r'^[1-9][0-9]{5}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a valid 6-digit PIN code.';

  static String? whole(String? value, int min, int max) {
    final text = value?.trim() ?? '';
    final parsed = int.tryParse(text);
    return !RegExp(r'^\d+$').hasMatch(text) ||
            parsed == null ||
            parsed < min ||
            parsed > max
        ? 'Enter a whole number from $min to $max.'
        : null;
  }
}

/// One accessible validation/focus/layout implementation for settings forms.
class StoreSettingsForm extends StatefulWidget {
  const StoreSettingsForm({
    required this.title,
    required this.detail,
    required this.fields,
    required this.saveKey,
    required this.saveLabel,
    required this.onSave,
    this.leading,
    this.trailing,
    this.embedded = false,
    this.pairAtWidth = 290,
    super.key,
  });
  final String title, detail, saveKey, saveLabel;
  final List<StoreSettingsInput> fields;
  final Widget? leading, trailing;
  final bool embedded;
  final double pairAtWidth;
  final VoidCallback onSave;

  @override
  State<StoreSettingsForm> createState() => _StoreSettingsFormState();
}

class _StoreSettingsFormState extends State<StoreSettingsForm> {
  final _form = GlobalKey<FormState>();
  // Embedded forms scroll with their parent. Never share an ExpansionTile's
  // PageStorage identifier (its bool is not a double scroll offset).
  final _embeddedScroll = ScrollController(keepScrollOffset: false);
  final _formStorage = PageStorageBucket();
  final _focus = <String, FocusNode>{};
  final _keys = <String, GlobalKey>{};
  bool _attempted = false;

  @override
  void dispose() {
    _embeddedScroll.dispose();
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _save() {
    setState(() => _attempted = true);
    if (!_form.currentState!.validate()) {
      final first = widget.fields.firstWhere(
        (field) => field.validate(field.controller.text) != null,
      );
      _focus[first.id]?.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _keys[first.id]?.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(
            target,
            alignment: .25,
            duration: const Duration(milliseconds: 180),
          );
        }
      });
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) => StoreSettingsStyle(
    child: PageStorage(
      bucket: _formStorage,
      child: Builder(
        builder: (context) => Form(
          key: _form,
          autovalidateMode: _attempted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            controller: widget.embedded ? _embeddedScroll : null,
            shrinkWrap: widget.embedded,
            primary: !widget.embedded,
            physics: widget.embedded
                ? const NeverScrollableScrollPhysics()
                : null,
            padding: const EdgeInsets.all(12),
            children: [
              if (!widget.embedded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (widget.detail.isNotEmpty)
                        Text(
                          widget.detail,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              if (widget.leading != null) widget.leading!,
              LayoutBuilder(
                builder: (context, constraints) {
                  final paired =
                      constraints.maxWidth >= widget.pairAtWidth &&
                      MediaQuery.textScalerOf(context).scale(14) <= 19;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final field in widget.fields)
                        SizedBox(
                          width: paired && !field.fullWidth
                              ? (constraints.maxWidth - 8) / 2
                              : constraints.maxWidth,
                          child: Container(
                            key: _keys.putIfAbsent(field.id, () => GlobalKey()),
                            child: TextFormField(
                              key: Key(field.id),
                              controller: field.controller,
                              minLines: 1,
                              maxLines: field.maxLines,
                              focusNode: _focus.putIfAbsent(
                                field.id,
                                () => FocusNode(),
                              ),
                              keyboardType: field.numeric
                                  ? TextInputType.number
                                  : TextInputType.text,
                              textInputAction: TextInputAction.next,
                              style: Theme.of(context).textTheme.bodyLarge,
                              validator: field.validate,
                              decoration: InputDecoration(
                                labelText: field.label,
                                prefixText: field.prefix,
                                suffixText: field.suffix,
                                helperText: field.helper,
                                helperMaxLines: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (widget.trailing != null) ...[
                const SizedBox(height: 8),
                widget.trailing!,
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                key: Key(widget.saveKey),
                onPressed: _save,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(widget.saveLabel),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Compact label/value row; stacks for enlarged text instead of clipping.
class StoreSettingsChoice<T> extends StatelessWidget {
  const StoreSettingsChoice({
    required this.label,
    required this.value,
    required this.controlKey,
    required this.options,
    required this.onChanged,
    super.key,
  });
  final String label, controlKey;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final picker = DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            key: Key(controlKey),
            value: value,
            isExpanded: true,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MoolColors.navy),
            items: [
              for (final item in options.entries)
                DropdownMenuItem(value: item.key, child: Text(item.value)),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        );
        if (MediaQuery.textScalerOf(context).scale(14) > 19 ||
            bounds.maxWidth < 270) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SizedBox(height: 6), Text(label), picker],
          );
        }
        return Row(
          children: [
            Expanded(child: Text(label)),
            Expanded(flex: 2, child: picker),
          ],
        );
      },
    ),
  );
}

/// Zero means unlimited; positive values are custom planning limits.
class StoreOrderLimit extends StatefulWidget {
  const StoreOrderLimit({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// Zero is an explicit unlimited planning preference, not zero capacity.
  final int value;
  final ValueChanged<int> onChanged;
  @override
  State<StoreOrderLimit> createState() => _StoreOrderLimitState();
}

class _StoreOrderLimitState extends State<StoreOrderLimit> {
  late final _count = TextEditingController(
    text: widget.value > 0 ? '${widget.value}' : '',
  );
  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  int? _parse(String text) =>
      RegExp(r'^\d+$').hasMatch(text.trim()) ? int.tryParse(text.trim()) : null;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Active orders'),
            if (widget.value != 0)
              SizedBox(
                width: 94,
                child: TextFormField(
                  key: const Key('work-status-order-limit'),
                  controller: _count,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  style: Theme.of(context).textTheme.bodyMedium,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Limit',
                    hintText: 'Number',
                    errorMaxLines: 3,
                  ),
                  validator: (value) => (_parse(value ?? '') ?? 0) > 0
                      ? null
                      : 'Enter 1 or more.',
                  onChanged: (value) => widget.onChanged(
                    (_parse(value) ?? 0) > 0 ? _parse(value)! : -1,
                  ),
                ),
              ),
            FilterChip(
              key: const Key('work-status-orders-unlimited'),
              label: const Text('Unlimited'),
              labelStyle: TextStyle(
                color: widget.value == 0 ? Colors.white : MoolColors.navy,
                fontWeight: FontWeight.w600,
              ),
              selected: widget.value == 0,
              onSelected: (selected) => widget.onChanged(
                selected
                    ? 0
                    : ((_parse(_count.text) ?? 0) > 0
                          ? _parse(_count.text)!
                          : -1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Text(
          'Planning only · pause orders yourself.',
          style: TextStyle(fontSize: 12, color: MoolColors.muted),
        ),
      ],
    ),
  );
}

/// Accept both retained AM/PM labels and 24-hour strings without resetting edits.
TimeOfDay? parseStoreHours(String value) {
  final match = RegExp(
    r'^\s*(\d{1,2}):(\d{2})\s*(AM|PM)?\s*$',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return null;
  var hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  final period = match[3]?.toUpperCase();
  if (minute > 59 || (period == null ? hour > 23 : hour < 1 || hour > 12)) {
    return null;
  }
  if (period != null) hour = hour % 12 + (period == 'PM' ? 12 : 0);
  return TimeOfDay(hour: hour, minute: minute);
}

String storeHoursValue(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
