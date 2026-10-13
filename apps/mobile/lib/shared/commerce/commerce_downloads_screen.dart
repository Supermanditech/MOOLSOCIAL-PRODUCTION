import 'package:flutter/material.dart';
import 'commerce_downloads.dart';

/// Shared customer/business surface. Source adapters own scoped retrieval;
/// frontend scope guards never replace backend document authorization.
class CommerceDownloadsScreen extends StatefulWidget {
  const CommerceDownloadsScreen({
    super.key,
    required this.scope,
    required this.source,
    required this.scopeChanges,
    required this.isCurrent,
    required this.title,
    required this.ownerLabel,
    required this.onExit,
    this.onStockStatement,
    this.stockStatementBuilder,
    this.customerStatementBuilder,
    this.searchPresentation,
    this.save = saveCommerceDownloadFile,
  });
  final CommerceDownloadScope scope;
  final CommerceDownloadSource source;
  final Listenable scopeChanges;
  final bool Function() isCurrent;
  final String title, ownerLabel;
  final VoidCallback onExit;
  final VoidCallback? onStockStatement;
  final WidgetBuilder? stockStatementBuilder;
  final WidgetBuilder? customerStatementBuilder;
  final Widget Function(TextField)? searchPresentation;
  final Future<bool> Function(CommerceDownloadFile) save;
  @override
  State<CommerceDownloadsScreen> createState() =>
      _CommerceDownloadsScreenState();
}

class _CommerceDownloadsScreenState extends State<CommerceDownloadsScreen> {
  Widget _presentSearch(TextField field) =>
      widget.searchPresentation?.call(field) ?? field;
  static const navy = Color(0xff000080);
  final _search = TextEditingController();
  final _from = TextEditingController(), _to = TextEditingController();
  final _items = <CommerceDownloadItem>[];
  final _cursors = <String>{};
  CommerceDownloadKind? _kind;
  DateTime? _start, _until;
  String _period = 'All time';
  String? _next, _error, _notice, _saving, _dateError;
  bool _loading = false, _stale = false;
  bool _stockOpen = false;
  bool _customerOpen = false;
  int _epoch = 0;
  int _scopeEpoch = 0;

  CommerceDownloadQuery get _query => CommerceDownloadQuery(
    scope: widget.scope,
    search: _search.text,
    kind: _kind,
    from: _start,
    until: _until,
  );
  @override
  void initState() {
    super.initState();
    widget.scopeChanges.addListener(_scopeChanged);
    _load();
  }

  void _scopeChanged() {
    if (!widget.isCurrent() && mounted) {
      setState(() {
        _epoch++;
        _scopeEpoch++;
        _stale = true;
        _items.clear();
        _loading = false;
        _saving = null;
        _error =
            'Your account or Store changed. Reopen Downloads in the correct account.';
        _notice = null;
      });
    }
  }

  @override
  void didUpdateWidget(covariant CommerceDownloadsScreen old) {
    super.didUpdateWidget(old);
    if (old.scopeChanges != widget.scopeChanges) {
      old.scopeChanges.removeListener(_scopeChanged);
      widget.scopeChanges.addListener(_scopeChanged);
    }
    if (old.scope.key != widget.scope.key || old.source != widget.source) {
      _epoch++;
      _scopeEpoch++;
      _stale = false;
      _items.clear();
      _saving = null;
      _load();
    }
  }

  @override
  void dispose() {
    _epoch++;
    widget.scopeChanges.removeListener(_scopeChanged);
    _search.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_stale || !widget.isCurrent()) {
      _scopeChanged();
      return;
    }
    if (more && (_loading || _next == null)) return;
    final epoch = ++_epoch;
    final query = _query;
    final cursor = more ? _next : null;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
      if (!more) {
        _items.clear();
        _next = null;
        _cursors.clear();
      }
    });
    try {
      final page = await widget.source
          .load(query, cursor: cursor)
          .timeout(const Duration(seconds: 20));
      if (!mounted || epoch != _epoch || !widget.isCurrent()) return;
      final ids = <String>{for (final item in _items) item.id};
      if (page.queryKey != query.key ||
          page.items.length > 100 ||
          page.items.any(
            (item) =>
                item.id.isEmpty || !query.matches(item) || !ids.add(item.id),
          ) ||
          (page.items.isEmpty && page.nextCursor != null) ||
          page.nextCursor != null &&
              (_cursors.contains(page.nextCursor) ||
                  page.nextCursor == cursor)) {
        throw const FormatException(
          'These documents could not be verified. Please retry.',
        );
      }
      setState(() {
        if (cursor != null) _cursors.add(cursor);
        _items.addAll(page.items);
        _next = page.nextCursor;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || epoch != _epoch || !widget.isCurrent()) return;
      setState(() {
        _loading = false;
        _error = error is FormatException
            ? error.message
            : 'Could not load documents. Please retry.';
      });
    }
  }

  Future<void> _download(CommerceDownloadItem item) async {
    if (_saving != null ||
        _stale ||
        !widget.isCurrent() ||
        item.scope.key != widget.scope.key) {
      return;
    }
    final scopeKey = widget.scope.key;
    final scopeEpoch = _scopeEpoch;
    setState(() {
      _saving = item.id;
      _notice = null;
    });
    try {
      final file = await item.load().timeout(const Duration(seconds: 30));
      if (!mounted ||
          _stale ||
          scopeEpoch != _scopeEpoch ||
          !widget.isCurrent() ||
          widget.scope.key != scopeKey) {
        return;
      }
      if (!file.valid || file.scope.key != scopeKey || file.id != item.id) {
        throw const FormatException(
          'The document does not match this account or Store.',
        );
      }
      final saved = await widget
          .save(file)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw const FormatException(
              'Download could not be confirmed. Check Downloads before retrying.',
            ),
          );
      if (!mounted ||
          _stale ||
          scopeEpoch != _scopeEpoch ||
          !widget.isCurrent() ||
          widget.scope.key != scopeKey) {
        return;
      }
      setState(
        () => _notice = saved
            ? 'Saved to Downloads / MoolSocial.'
            : 'Download could not be confirmed. Check Downloads before retrying.',
      );
    } catch (error) {
      if (!mounted ||
          _stale ||
          scopeEpoch != _scopeEpoch ||
          !widget.isCurrent() ||
          widget.scope.key != scopeKey) {
        return;
      }
      setState(
        () => _notice = error is FormatException
            ? error.message
            : 'Could not download this document. Tap PDF to retry.',
      );
    } finally {
      if (mounted &&
          scopeEpoch == _scopeEpoch &&
          widget.scope.key == scopeKey) {
        setState(() => _saving = null);
      }
    }
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _period = period;
      _showPeriods = period == 'Custom';
      _showKinds = false;
      _dateError = null;
      _start = switch (period) {
        'Today' => today,
        'This week' => today.subtract(Duration(days: today.weekday - 1)),
        'This month' => DateTime(now.year, now.month),
        _ => null,
      };
      _until = period == 'All time' || period == 'Custom'
          ? null
          : today.add(const Duration(days: 1));
      if (period == 'Custom') {
        _epoch++;
        _items.clear();
        _next = null;
        _loading = false;
        _error = null;
      }
    });
    if (period != 'Custom') _load();
  }

  DateTime? _date(String input) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(input.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!),
        month = int.parse(match[2]!),
        year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  String _label(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  void _invalidateDates(String _) {
    setState(() {
      _epoch++;
      _start = null;
      _until = null;
      _items.clear();
      _next = null;
      _loading = false;
      _error = null;
      _dateError = null;
    });
  }

  static const _kinds = <CommerceDownloadKind?, String>{
    null: 'All documents',
    CommerceDownloadKind.invoice: 'Invoices',
    CommerceDownloadKind.platformFee: 'MoolSocial fees',
    CommerceDownloadKind.summary: 'Order summaries',
  };
  bool _showKinds = false, _showPeriods = false;
  static const _muted = Color(0xff636b80);
  static const _line = Color(0xffe8ebf2);

  Widget _filterButton(
    String key,
    IconData icon,
    String label,
    bool expanded,
    VoidCallback action,
  ) => TextButton(
    key: Key(key),
    onPressed: _stale ? null : action,
    style: TextButton.styleFrom(
      foregroundColor: navy,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      minimumSize: const Size(0, 44),
    ),
    child: Row(
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Icon(
          expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 17,
        ),
      ],
    ),
  );

  Widget _choice(String label, bool selected, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(right: 4),
    child: TextButton(
      onPressed: _stale ? null : action,
      style: TextButton.styleFrom(
        foregroundColor: selected ? navy : _muted,
        backgroundColor: selected
            ? const Color(0xffedf0f9)
            : Colors.transparent,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );

  void _applyDates() {
    final start = _date(_from.text), end = _date(_to.text);
    if (start == null || end == null || end.isBefore(start)) {
      setState(
        () => _dateError = 'Enter valid dates with To on or after From.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _start = start;
      _until = end.add(const Duration(days: 1));
      _dateError = null;
      _showPeriods = false;
    });
    _load();
  }

  Widget _customDates() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        Widget field(
          String name,
          TextEditingController controller,
          String key,
        ) => TextField(
          key: Key(key),
          controller: controller,
          onChanged: _invalidateDates,
          enabled: !_stale,
          keyboardType: TextInputType.datetime,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: name,
            hintText: 'DD/MM/YYYY',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: navy),
            ),
          ),
        );
        final from = field('From', _from, 'downloads-date-from');
        final to = field('To', _to, 'downloads-date-to');
        final compact =
            constraints.maxWidth >= 300 &&
            MediaQuery.textScalerOf(context).scale(13) <= 18;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact)
              Row(
                children: [
                  Expanded(child: from),
                  const SizedBox(width: 8),
                  Expanded(child: to),
                ],
              )
            else ...[
              from,
              const SizedBox(height: 10),
              to,
            ],
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('downloads-apply-dates'),
                onPressed: _stale ? null : _applyDates,
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text(
                  'Apply dates',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ),
            if (_dateError != null)
              Text(
                _dateError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        );
      },
    ),
  );

  Widget _filterBar(bool enlarged) {
    final kind = _filterButton(
      'downloads-kind-toggle',
      Icons.filter_list_rounded,
      _kinds[_kind]!,
      _showKinds,
      () {
        setState(() {
          _showKinds = !_showKinds;
          _showPeriods = false;
        });
      },
    );
    final period = _filterButton(
      'downloads-period-toggle',
      Icons.calendar_today_outlined,
      _period == 'Custom' ? 'Custom dates' : _period,
      _showPeriods,
      () {
        setState(() {
          _showPeriods = !_showPeriods;
          _showKinds = false;
        });
      },
    );
    return enlarged
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              kind,
              const Divider(height: 1, color: _line),
              period,
            ],
          )
        : Row(
            children: [
              Expanded(child: kind),
              const SizedBox(
                height: 22,
                child: VerticalDivider(width: 1, color: _line),
              ),
              Expanded(child: period),
            ],
          );
  }

  Widget _record(CommerceDownloadItem item) {
    final enlarged = MediaQuery.textScalerOf(context).scale(13) > 18;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.reference,
          style: const TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.party,
          style: const TextStyle(color: Color(0xff313b50), fontSize: 12),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 3,
          children: [
            Text(
              _label(item.date.toLocal()),
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
            Text(
              item.title,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
        if (item.notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.notice!,
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ),
        if (item.unavailableReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.unavailableReason!,
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
      ],
    );
    final action = _saving == item.id
        ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : TextButton.icon(
            key: ValueKey('download-${item.id}'),
            onPressed:
                _saving != null || _stale || item.unavailableReason != null
                ? null
                : () => _download(item),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text(
              'PDF',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: navy,
              backgroundColor: const Color(0xfff3f5fb),
              minimumSize: const Size(64, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: enlarged
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: action),
              ],
            )
          : Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 10),
                action,
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enlarged = MediaQuery.textScalerOf(context).scale(13) > 18;
    final stockLink =
        widget.scope.store == null ||
            (widget.onStockStatement == null &&
                widget.stockStatementBuilder == null)
        ? null
        : TextButton.icon(
            key: const Key('downloads-stock-statement'),
            onPressed: _stale
                ? null
                : () {
                    if (widget.isCurrent()) {
                      if (widget.stockStatementBuilder != null) {
                        setState(() {
                          _stockOpen = !_stockOpen;
                          _customerOpen = false;
                        });
                      } else {
                        widget.onStockStatement!();
                      }
                    } else {
                      _scopeChanged();
                    }
                  },
            icon: const Icon(Icons.table_rows_outlined, size: 16),
            label: Text(
              _stockOpen ? 'Documents' : 'Stock statement',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 44),
            ),
          );
    final owner = Text(
      widget.ownerLabel,
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: enlarged ? 88 : kToolbarHeight,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: widget.onExit,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          widget.title,
          maxLines: 2,
          softWrap: true,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (widget.scope.store != null &&
                widget.customerStatementBuilder != null) ...[
              owner,
              Wrap(
                spacing: 4,
                children: [
                  ?stockLink,
                  TextButton.icon(
                    key: const Key('downloads-customer-statements'),
                    onPressed: _stale
                        ? null
                        : () {
                            if (!widget.isCurrent()) {
                              _scopeChanged();
                              return;
                            }
                            setState(() {
                              _customerOpen = !_customerOpen;
                              _stockOpen = false;
                            });
                          },
                    icon: const Icon(Icons.people_outline, size: 16),
                    label: Text(
                      _customerOpen ? 'Documents' : 'Customer statements',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ),
            ] else if (enlarged) ...[
              owner,
              if (stockLink != null)
                Align(alignment: Alignment.centerLeft, child: stockLink),
            ] else
              Row(
                children: [
                  Expanded(child: owner),
                  ?stockLink,
                ],
              ),
            if (_customerOpen &&
                widget.scope.store != null &&
                widget.customerStatementBuilder != null &&
                !_stale)
              widget.customerStatementBuilder!(context)
            else if (_stockOpen &&
                widget.scope.store != null &&
                widget.stockStatementBuilder != null &&
                !_stale)
              widget.stockStatementBuilder!(context)
            else ...[
              _presentSearch(
                TextField(
                  key: const Key('downloads-search'),
                  controller: _search,
                  enabled: !_stale,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 21),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: 28,
                      minHeight: 44,
                    ),
                    hintText: 'Search invoice, order or name',
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (_) {
                    if (_period != 'Custom' || _start != null) {
                      _load();
                    }
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xfff2f4fa), Color(0xfffafbfe)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  children: [
                    _filterBar(enlarged),
                    if (_showKinds)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final choice in _kinds.entries)
                              _choice(choice.value, _kind == choice.key, () {
                                setState(() {
                                  _kind = choice.key;
                                  _showKinds = false;
                                });
                                if (_period != 'Custom' || _start != null) {
                                  _load();
                                }
                              }),
                          ],
                        ),
                      ),
                    if (_showPeriods) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final period in [
                              'All time',
                              'Today',
                              'This week',
                              'This month',
                              'Custom',
                            ])
                              _choice(
                                period,
                                _period == period,
                                () => _setPeriod(period),
                              ),
                          ],
                        ),
                      ),
                      if (_period == 'Custom') _customDates(),
                    ],
                  ],
                ),
              ),
              if (_period == 'Custom' && _start != null && !_showPeriods)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_label(_start!)} – ${_label(_until!.subtract(const Duration(days: 1)))}',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 16),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _notice!,
                      style: const TextStyle(fontSize: 12, color: navy),
                    ),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: _muted,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      if (!_stale)
                        TextButton(
                          onPressed: () => _load(),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              if (!_loading && _error == null && _items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    _period == 'Custom' && _start == null
                        ? 'Choose dates to view documents.'
                        : 'No documents match these filters.',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ),
              for (final item in _items) ...[
                _record(item),
                const Divider(height: 1, color: _line),
              ],
              if (_next != null && !_loading && !_stale)
                TextButton(
                  onPressed: () => _load(more: true),
                  child: const Text('Load more'),
                ),
              if (widget.scope.store != null)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Text(
                    'Other reports appear here when available.',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
