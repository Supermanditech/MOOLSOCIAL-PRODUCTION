import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../work_models.dart';
import '../work_session.dart';

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
    this.saveEnabled = true,
    super.key,
  });
  final String title, detail, saveKey, saveLabel;
  final List<StoreSettingsInput> fields;
  final Widget? leading, trailing;
  final bool embedded;
  final bool saveEnabled;
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
    if (!widget.saveEnabled) return;
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
                onPressed: widget.saveEnabled ? _save : null,
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

/// Frontend-only supplied values. Identity and permission are native owners.
class StoreSettingsInitialData {
  StoreSettingsInitialData._(this.actionId, this.fields);
  final String actionId;
  final Map<String, Object?> fields;
  static const publicText = {'legalName', 'street', 'city', 'state', 'pinCode',
    'publicContactPhone', 'billingAddress', 'pan', 'cin', 'fssai', 'signatory',
    'returnSummary', 'returnConditions'};
  static Set<String> keys(String action) => switch (action) {
    'AI-ACT-317' => {'workspaceId'},
    'AI-ACT-318' => {'acceptingOrders', 'fulfilmentMode', 'busyMinutes', 'reopensAt'},
    'AI-ACT-319' => {'openingTime', 'closingTime', 'maximumActiveOrders', 'alertSound',
      'alertVibration', 'preparationMinutes', 'fulfilmentPreference'},
    'AI-ACT-320' => {...publicText, 'businessType', 'retailChannelEnabled',
      'wholesaleChannelEnabled', 'wholesalePaymentTerms', 'returnRemedies',
      'returnWindowDays', 'dispatchDays'},
    'AI-ACT-321' => {},
    'AI-ACT-322' => {'city', 'area', 'pincode', 'pickupEnabled'},
    'AI-ACT-323' => {'mode'},
    'AI-ACT-324' => {'address', 'payeeName', 'merchantCode'},
    'AI-ACT-326' => {'staffAccessEnabled', 'counterCount'},
    'AI-ACT-327' => {'visibleToCustomers'},
    'AI-ACT-328' => {'alertId'},
    _ => throw const FormatException('This Store task is unavailable.'),
  };
  factory StoreSettingsInitialData.fromFields(String action, Map<String, Object?> fields) {
    final allowed = keys(action);
    if (fields.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('Use only the supported Store fields.');
    }
    const booleans = {'acceptingOrders', 'alertSound', 'alertVibration', 'pickupEnabled',
      'staffAccessEnabled', 'visibleToCustomers', 'retailChannelEnabled', 'wholesaleChannelEnabled'};
    const integers = {'busyMinutes', 'preparationMinutes', 'maximumActiveOrders',
      'counterCount', 'returnWindowDays', 'dispatchDays'};
    for (final entry in fields.entries) {
      final key = entry.key, value = entry.value;
      if (booleans.contains(key)) {
        if (value is! bool) throw const FormatException('Choose an on/off value.');
      } else if (integers.contains(key)) {
        if (key == 'returnWindowDays' && value == null) continue;
        if (value is! int || value < 0 || key == 'counterCount' && (value < 1 || value > 20) ||
            {'dispatchDays', 'returnWindowDays'}.contains(key) && value > 365) {
          throw const FormatException('Check the whole-number setting.');
        }
      } else if (key == 'wholesalePaymentTerms') {
        if (value is! List || value.any((v) => v is! Map ||
            v.keys.any((k) => !const {'kind', 'advancePercent', 'netDays'}.contains(k)))) {
          throw const FormatException('Choose supported payment terms.');
        }
        WorkspacePaymentTerm.decodeList(value);
      } else if (key == 'returnRemedies') {
        if (value is! List || value.any((v) => v is! String ||
            !WorkspaceStorePublicationDetails.remedies.contains(v)) || value.toSet().length != value.length) {
          throw const FormatException('Choose supported return remedies.');
        }
      } else if (value is! String || value.length > 2000 || RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(value)) {
        throw const FormatException('Enter a supported text value.');
      }
      if ({'openingTime', 'closingTime'}.contains(key) &&
          !WorkspaceStorePublicationDetails.validTradingTime(value as String)) {
        throw const FormatException('Choose a valid trading time.');
      }
      if ({'fulfilmentMode', 'fulfilmentPreference'}.contains(key) &&
          !const {'Delivery and pickup', 'Pickup only', 'Delivery only'}.contains(value)) {
        throw const FormatException('Choose a supported fulfilment preference.');
      }
      if (key == 'mode' && !WorkspaceInvoiceDeliveryMode.values.any((mode) => mode.name == value)) {
        throw const FormatException('Choose a supported invoice preference.');
      }
      if (key == 'businessType' && !WorkspaceStorePublicationDetails.businessTypes.containsKey(value)) {
        throw const FormatException('Choose a supported business type.');
      }
    }
    if (action == 'AI-ACT-317' && (fields['workspaceId'] is! String || (fields['workspaceId'] as String).isEmpty) ||
        action == 'AI-ACT-328' && (fields['alertId'] is! String || (fields['alertId'] as String).isEmpty) ||
        action != 'AI-ACT-321' && fields.isEmpty) {
      throw const FormatException('Choose the setting to review.');
    }
    // Raw partial text is preserved; native validators validate the complete form.
    Object? freeze(Object? value) => value is List ? List<Object?>.unmodifiable(value.map(freeze))
      : value is Map ? Map<String, Object?>.unmodifiable({for (final entry in value.entries) entry.key as String: freeze(entry.value)}) : value;
    return StoreSettingsInitialData._(action, Map.unmodifiable({for (final entry in fields.entries) entry.key: freeze(entry.value)}));
  }
}

class StoreSettingsReviewScope {
  StoreSettingsReviewScope({required bool Function() current, required bool Function() sourceCurrent,
    this.readSource, this.readOperation, this.destinationFingerprint, this.invoiceMode, this.changes, this.sourceChanges})
    : _ownerCurrent = current, _originalCurrent = sourceCurrent {
    _baseline = readSource == null ? null : _copy(readSource!());
    _originalOperation = readOperation?.call();
    sourceChanges?.addListener(_observeSource);
    if (!identical(changes, sourceChanges)) changes?.addListener(_observeSource);
  }
  final bool Function() _ownerCurrent;
  final bool Function() _originalCurrent;
  final Map<String, Object?> Function()? readSource;
  final String? Function()? readOperation;
  Map<String, Object?>? _baseline, _attempt;
  List<Map<String, Object?>> _attemptStates = [];
  String? _originalOperation, _ownOperation, _resolvingOperation;
  bool _sourceRetired = false, _disposed = false;
  final String? destinationFingerprint;
  final String? invoiceMode;
  final Listenable? changes;
  final Listenable? sourceChanges;
  bool current() {
    if (_disposed) return false;
    if (!_ownerCurrent()) { dispose(); return false; }
    return true;
  }
  void _observeSource() { try { if (current()) sourceCurrent(); } on Object { _sourceRetired = true; } }
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    sourceChanges?.removeListener(_observeSource);
    if (!identical(changes, sourceChanges)) changes?.removeListener(_observeSource);
  }
  static Map<String, Object?> _copy(Map<String, Object?> value) => Map<String, Object?>.from(jsonDecode(jsonEncode(value)) as Map);
  static Object? _ordered(Object? value) => value is Map
    ? {for (final key in value.keys.cast<String>().toList()..sort()) key: _ordered(value[key])}
    : value is List ? value.map(_ordered).toList() : value;
  static bool _equal(Object? a, Object? b) => jsonEncode(_ordered(a)) == jsonEncode(_ordered(b));
  bool get _fieldsCurrent => readSource == null ? _originalCurrent() :
    _equal(readSource!(), _baseline) || _attemptStates.any((state) => _equal(readSource!(), state));
  bool sourceCurrent() {
    if (!current() || _sourceRetired) return false;
    final admitted = _fieldsCurrent && (readOperation == null || readOperation!() == _originalOperation ||
      _ownOperation != null && readOperation!() == _ownOperation || readOperation!() == null &&
      _resolvingOperation != null && {_originalOperation, _ownOperation}.contains(_resolvingOperation));
    if (!admitted) _sourceRetired = true;
    return admitted;
  }
  bool get mayApply => current() && sourceCurrent();
  /// Exact admitted payload remains retryable if native memory changes before
  /// a failed durable write. No other field/revision or different retry enters.
  bool beginAttempt(Map<String, Object?> target, {List<Map<String, Object?>> intermediate = const []}) {
    if (!mayApply) return false;
    if (readSource == null) return true;
    final next = {..._baseline!, ..._copy(target)};
    if (_attempt != null) return _equal(_attempt, next);
    _attempt = next;
    _attemptStates = [for (final state in intermediate) {..._baseline!, ..._copy(state)}, next];
    return true;
  }
  void completeAttempt() {
    if (!current() || _sourceRetired || _attempt == null || readSource == null || !_equal(readSource!(), _attempt)) return;
    _baseline = _copy(readSource!()); _attempt = null; _attemptStates = [];
  }
  bool admitOriginal(String fingerprint) {
    if (!mayApply || readOperation == null || readOperation!() != null || _originalOperation != null || _ownOperation != null) return false;
    _ownOperation = fingerprint; return true;
  }
  /// The original controller calls this only after its exact known result and
  /// journal cleanup, immediately before its own pending-clear notification.
  void admitOriginalResolution(String fingerprint) {
    if (!current() || _sourceRetired || !_fieldsCurrent ||
        !{_originalOperation, _ownOperation}.contains(fingerprint)) return;
    _resolvingOperation = fingerprint;
  }
  void completeOriginal() {
    if (!current() || _sourceRetired || !_fieldsCurrent || readOperation == null || readOperation!() != null ||
        _ownOperation == null && _originalOperation == null) return;
    _ownOperation = null; _originalOperation = null; _resolvingOperation = null;
  }
}

String storeUpiFingerprint(WorkspaceUpiDestination? destination) => jsonEncode(
  destination == null ? null : [destination.address, destination.payeeName, destination.merchantCode]);

class _StoreUpiDraft {
  const _StoreUpiDraft(this.address, this.payee, this.merchant, this.baseline, this.attempt, this.unknown);
  final String address, payee, merchant;
  final WorkspaceUpiDestination? baseline, attempt;
  final bool unknown;
}
final _storeUpiDrafts = <Object, _StoreUpiDraft>{};
bool storeUpiDestinationHasDraft(WorkSession session) => _storeUpiDrafts.containsKey(
  (session, session.storeUpiScope, session.navigationScopeRevision, session.publicationPreferencesContext));

/// Keeps the existing State/draft alive while retiring private rendered fields.
class StoreSettingsReviewFrame extends StatelessWidget {
  const StoreSettingsReviewFrame({required this.session, required this.scope, required this.child, super.key});
  final WorkSession session;
  final StoreSettingsReviewScope? scope;
  final Widget child;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: Listenable.merge([session, scope?.changes]),
    builder: (context, _) {
      final active = scope?.current() != false;
      return Stack(fit: StackFit.expand, children: [
        Offstage(offstage: !active, child: ExcludeFocus(excluding: !active, child: child)),
        if (!active) const Center(child: Text('Your Store or account changed. Your entries are kept. Reopen this task.')),
      ]);
    });
}

/// One native editor for manual Settings and AI Review; never verifies a bank.
class StoreUpiDestinationEditor extends StatefulWidget {
  const StoreUpiDestinationEditor({required this.session, this.initialData, this.reviewScope, super.key});
  final WorkSession session;
  final StoreSettingsInitialData? initialData;
  final StoreSettingsReviewScope? reviewScope;
  @override State<StoreUpiDestinationEditor> createState() => _StoreUpiDestinationEditorState();
}
class _StoreUpiDestinationEditorState extends State<StoreUpiDestinationEditor> {
  late final _owner = widget.session;
  late final _scope = _owner.storeUpiScope;
  late final _navigation = _owner.navigationScopeRevision;
  late final _principal = _owner.publicationPreferencesContext;
  final _address = TextEditingController(), _payee = TextEditingController(), _merchant = TextEditingController();
  late final StoreSettingsReviewScope _presentationScope;
  WorkspaceUpiDestination? _baseline, _attempt;
  WorkspaceUpiDestination? _checkedSaved;
  bool _checkedDifferent = false;
  bool _busy = true, _loaded = false, _unknown = false;
  String? _message;
  late final _draftKey = (_owner, _scope, _navigation, _principal);
  bool get _current => mounted && identical(_owner, widget.session) && _scope != null &&
    _scope == _owner.storeUpiScope && _navigation == _owner.navigationScopeRevision &&
    _principal == _owner.publicationPreferencesContext && widget.reviewScope?.current() != false;
  bool _same(WorkspaceUpiDestination? a, WorkspaceUpiDestination? b) => a?.address == b?.address &&
    a?.payeeName == b?.payeeName && a?.merchantCode == b?.merchantCode;
  WorkspaceUpiDestination _candidate() => WorkspaceUpiDestination(account: _scope!.account,
    store: _scope.store, address: _address.text, payeeName: _payee.text, merchantCode: _merchant.text);
  void _remember() {
    if (!_loaded) return;
    if (!_unknown && _same(_candidate(), _baseline)) { _storeUpiDrafts.remove(_draftKey); return; }
    _storeUpiDrafts[_draftKey] = _StoreUpiDraft(_address.text, _payee.text, _merchant.text, _baseline, _attempt, _unknown);
  }
  @override void initState() {
    super.initState();
    _presentationScope = StoreSettingsReviewScope(current: () => _current, sourceCurrent: () => true, changes: widget.reviewScope?.changes);
    final draft = _storeUpiDrafts[_draftKey];
    if (draft != null) {
      _address.text = draft.address; _payee.text = draft.payee; _merchant.text = draft.merchant;
      _baseline = draft.baseline; _attempt = draft.attempt; _unknown = draft.unknown; _loaded = true;
    }
    for (final field in [_address, _payee, _merchant]) { field.addListener(_remember); }
    unawaited(_load(check: _unknown));
  }
  Future<void> _load({bool check = false}) async {
    if (!_current) return;
    setState(() { _busy = true; _message = null; });
    try {
      final saved = await _owner.loadStoreUpiDestination(_scope!);
      if (!_current) return;
      if (check) {
        if (_attempt != null && _same(saved, _attempt)) {
          _baseline = saved; _unknown = false; _attempt = null;
          _message = 'UPI details saved on this device.';
        } else {
          _checkedSaved = saved; _checkedDifferent = true;
          _message = 'Saved details do not match the attempted save. Your entries are kept. Compare them before trying again.';
        }
      } else if (!_loaded && widget.reviewScope?.sourceCurrent() != false &&
          (widget.reviewScope?.destinationFingerprint == null ||
           widget.reviewScope!.destinationFingerprint == storeUpiFingerprint(saved))) {
        _baseline = saved;
        final fields = widget.initialData?.fields ?? const <String, Object?>{};
        _address.text = fields['address'] as String? ?? saved?.address ?? '';
        _payee.text = fields['payeeName'] as String? ?? saved?.payeeName ?? '';
        _merchant.text = fields['merchantCode'] as String? ?? saved?.merchantCode ?? '';
        _loaded = true;
      } else if (!_loaded) { _message = 'Saved details changed. Reopen this task. Your entries are kept.'; }
    } on Object {
      if (_current) _message = check ? 'The save is unconfirmed. Check saved details again. Your entries are kept.'
        : 'Could not open saved UPI details. Try again.';
    } finally { if (_current) { _remember(); setState(() => _busy = false); } }
  }
  Future<void> _save() async {
    if (!_current || !_loaded || _busy || _unknown || widget.reviewScope?.mayApply == false) return;
    final candidate = _candidate();
    if (!candidate.valid) return;
    setState(() { _busy = true; _message = null; });
    try {
      final latest = await _owner.loadStoreUpiDestination(_scope!);
      if (!_current || widget.reviewScope?.mayApply == false) return;
      if (!_same(latest, _baseline)) {
        _unknown = true; _attempt = null; _checkedSaved = latest; _checkedDifferent = true;
        _remember();
        _message = 'Saved UPI details changed. Your entries are kept. Compare them before saving again.';
        return;
      }
      _attempt = candidate; _unknown = true;
      _remember();
      await _owner.saveStoreUpiDestination(candidate, current: () => _current && widget.reviewScope?.mayApply != false,
        expectedDestinationFingerprint: storeUpiFingerprint(_baseline));
      if (!_current) return;
      final actual = await _owner.loadStoreUpiDestination(_scope);
      if (!_current) return;
      if (_same(actual, candidate)) {
        _baseline = actual; _attempt = null; _unknown = false;
        _message = 'UPI details saved on this device.';
      } else { _message = 'The save is unconfirmed. Check saved details. Your entries are kept.'; }
    } on Object {
      if (_current) _message = 'The save is unconfirmed. Check saved details. Your entries are kept.';
    } finally { if (_current) { _remember(); setState(() => _busy = false); } }
  }
  @override void dispose() { _remember(); _presentationScope.dispose(); _address.dispose(); _payee.dispose(); _merchant.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => StoreSettingsReviewFrame(session: _owner,
    scope: _presentationScope,
    child: StoreSettingsForm(title: 'Store UPI details',
      detail: _message ?? (_busy ? 'Opening saved details…' : 'Payment destination on this device. Bank and payee verification are separate.'),
      fields: [
        StoreSettingsInput(id: 'work-upi-address', label: 'UPI ID', controller: _address,
          validate: (value) => value != null && value.length <= 256 && RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+$').hasMatch(value) ? null : 'Enter a valid UPI ID.'),
        StoreSettingsInput(id: 'work-upi-payee', label: 'Payee name', controller: _payee,
          validate: (value) => value != null && value.trim().isNotEmpty && value == value.trim() && value.length <= 100 &&
            !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ? null : 'Enter the payee name without extra spaces.'),
        StoreSettingsInput(id: 'work-upi-merchant', label: 'Merchant code (optional)', controller: _merchant, numeric: true,
          validate: (value) => value == null || value.isEmpty || RegExp(r'^\d{4}$').hasMatch(value) ? null : 'Enter a 4-digit merchant code.'),
      ], saveKey: 'work-upi-save', saveLabel: _busy ? 'Saving…' : 'Save UPI details',
      saveEnabled: _current && _loaded && !_busy && !_unknown && widget.reviewScope?.mayApply != false, onSave: _save,
      trailing: !_loaded || _unknown ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton(key: const Key('work-upi-check'), onPressed: _busy ? null : () => _load(check: _unknown),
          child: Text(_unknown ? 'Check saved details' : 'Try again')),
        if (_checkedDifferent) ...[
          Text(_checkedSaved == null ? 'No UPI destination is saved on this device.'
            : 'Saved on this device: ${_checkedSaved!.address} · ${_checkedSaved!.payeeName}'),
          TextButton(key: const Key('work-upi-review-again'), onPressed: _busy ? null : () {
            if (!_current) return;
            setState(() { _baseline = _checkedSaved; _unknown = false; _attempt = null; _checkedDifferent = false;
              _message = 'Your entries are kept. Review them before saving again.'; });
            _remember();
          }, child: const Text('Review my entries again')),
        ],
      ]) : null));
}
