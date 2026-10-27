import 'package:flutter/material.dart';

enum GlobalAccountPlanAudience { personal, business }

enum GlobalAccountPlansStatus { loading, unavailable, failed, ready }

/// Read-only billing presentation. Payment/entitlement authority stays with
/// PROFILE-B02; this screen never activates a plan or updates a local boolean.
@immutable
class GlobalAccountPlanOffer {
  const GlobalAccountPlanOffer({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.features,
    this.eligible = false,
  });
  final String id;
  final String name;

  /// Includes currency, billing period and tax wording from the catalogue.
  final String priceLabel;
  final List<String> features;
  final bool eligible;
}

@immutable
class GlobalAccountPlansViewData {
  const GlobalAccountPlansViewData({
    required this.accountScope,
    required this.revision,
    required this.audience,
    required this.status,
    this.offers = const [],
    this.currentPlanId,
    this.subscriptionLabel,
    this.canManage = false,
  });
  final Object accountScope;
  final String revision;
  final GlobalAccountPlanAudience audience;
  final GlobalAccountPlansStatus status;
  final List<GlobalAccountPlanOffer> offers;

  /// Only confirmed billing readback may populate these values.
  final String? currentPlanId;
  final String? subscriptionLabel;
  final bool canManage;
}

class GlobalAccountPlansV2 extends StatefulWidget {
  const GlobalAccountPlansV2({
    required this.accountScope,
    required this.accountAuthenticated,
    required this.onClose,
    this.data,
    this.onAudienceChanged,
    this.onReview,
    this.onManage,
    this.onRetry,
    super.key,
  });
  final Object? accountScope;
  final bool accountAuthenticated;
  final VoidCallback onClose;
  final GlobalAccountPlansViewData? data;
  final ValueChanged<GlobalAccountPlanAudience>? onAudienceChanged;

  /// Native review handoff only; it must retain the source revision.
  final Future<void> Function(GlobalAccountPlanOffer offer, String revision)?
  onReview;
  final Future<void> Function(String revision)? onManage;
  final VoidCallback? onRetry;

  @override
  State<GlobalAccountPlansV2> createState() => _GlobalAccountPlansV2State();
}

class _GlobalAccountPlansV2State extends State<GlobalAccountPlansV2> {
  GlobalAccountPlanAudience _audience = GlobalAccountPlanAudience.personal;
  bool _opening = false;
  String? _error;
  int _generation = 0;

  @override
  void didUpdateWidget(GlobalAccountPlansV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountScope != widget.accountScope ||
        oldWidget.accountAuthenticated != widget.accountAuthenticated ||
        oldWidget.data != widget.data) {
      _generation++;
      _opening = false;
      _error = null;
      if (oldWidget.accountScope != widget.accountScope) {
        _audience = GlobalAccountPlanAudience.personal;
      }
    }
  }

  GlobalAccountPlansViewData? get _data {
    final data = widget.data;
    if (!widget.accountAuthenticated ||
        widget.accountScope == null ||
        data == null ||
        data.accountScope != widget.accountScope ||
        data.audience != _audience ||
        data.revision.trim().isEmpty ||
        data.offers.any(
          (offer) =>
              offer.id.trim().isEmpty ||
              offer.name.trim().isEmpty ||
              offer.priceLabel.trim().isEmpty,
        ) ||
        data.offers.map((offer) => offer.id).toSet().length !=
            data.offers.length) {
      return null;
    }
    return data;
  }

  Future<void> _handoff(
    GlobalAccountPlansViewData source,
    Future<void> Function() action, {
    required int expectedGeneration,
    GlobalAccountPlanOffer? offer,
  }) async {
    if (!mounted ||
        expectedGeneration != _generation ||
        _opening ||
        !identical(_data, source) ||
        source.status != GlobalAccountPlansStatus.ready) {
      return;
    }
    if (offer != null &&
        (!source.offers.contains(offer) ||
            !offer.eligible ||
            source.currentPlanId == offer.id)) {
      return;
    }
    final generation = _generation;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      await action();
    } on Object {
      if (mounted && generation == _generation) {
        setState(() => _error = 'Could not open billing. Try again.');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _opening = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final generation = _generation;
    final ready = data?.status == GlobalAccountPlansStatus.ready;
    return Scaffold(
      key: const Key('global-account-plans-v2'),
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FC),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF23252B),
        title: const Text(
          'Plans & billing',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: widget.onClose,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<GlobalAccountPlanAudience>(
                  style: SegmentedButton.styleFrom(
                    foregroundColor: const Color(0xFF23252B),
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: const Color(0xFF0000FF),
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: GlobalAccountPlanAudience.personal,
                      label: Text('Personal'),
                    ),
                    ButtonSegment(
                      value: GlobalAccountPlanAudience.business,
                      label: Text('Business'),
                    ),
                  ],
                  selected: {_audience},
                  onSelectionChanged: _opening
                      ? null
                      : (selection) {
                          setState(() {
                            _audience = selection.single;
                            _error = null;
                            _generation++;
                          });
                          widget.onAudienceChanged?.call(_audience);
                        },
                ),
                const SizedBox(height: 16),
                if (!widget.accountAuthenticated)
                  const Text('Sign in to view plans for your account.')
                else if (widget.accountScope == null)
                  const Text(
                    'Plans are not available for this account right now.',
                  )
                else if (data?.status == GlobalAccountPlansStatus.loading)
                  const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading plans',
                    ),
                  )
                else if (!ready) ...[
                  Text(
                    data?.status == GlobalAccountPlansStatus.failed
                        ? 'Could not load plans.'
                        : 'Plans are not available right now.',
                  ),
                  if (widget.onRetry != null)
                    TextButton(
                      onPressed: widget.onRetry,
                      child: const Text('Try again'),
                    ),
                ] else ...[
                  if (data!.subscriptionLabel case final label?)
                    Text(
                      label,
                      key: const Key('global-account-plan-status'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (data.canManage && widget.onManage != null)
                    OutlinedButton(
                      onPressed: _opening
                          ? null
                          : () => _handoff(data, () async {
                              await widget.onManage?.call(data.revision);
                            }, expectedGeneration: generation),
                      child: const Text('Manage plan'),
                    ),
                  if (data.offers.isEmpty)
                    const Text('No plans are available for this account.'),
                  for (final offer in data.offers)
                    Card(
                      margin: const EdgeInsets.only(top: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              offer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              offer.priceLabel,
                              style: const TextStyle(fontSize: 15),
                            ),
                            for (final feature in offer.features)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(feature),
                              ),
                            const SizedBox(height: 12),
                            if (offer.id == data.currentPlanId)
                              const Text('Current plan')
                            else
                              FilledButton(
                                onPressed:
                                    !offer.eligible ||
                                        _opening ||
                                        widget.onReview == null
                                    ? null
                                    : () => _handoff(
                                        data,
                                        () async {
                                          await widget.onReview?.call(
                                            offer,
                                            data.revision,
                                          );
                                        },
                                        expectedGeneration: generation,
                                        offer: offer,
                                      ),
                                child: const Text('Review plan'),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!),
                  ),
                if (_audience == GlobalAccountPlanAudience.business) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Workspace activation requires documents and MoolSocial approval.',
                    style: TextStyle(color: Color(0xFF666A73), fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
