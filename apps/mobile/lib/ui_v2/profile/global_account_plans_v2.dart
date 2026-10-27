import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/journey01/account_plans_gateway.dart';

enum GlobalAccountPlanAudience { personal, business }

enum GlobalWorkspacePlanGuide { unknown, available, application, approved }

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
    this.version = '',
    this.recommended = false,
    this.featureIds = const [],
  });
  final String id;
  final String name;

  /// Includes currency, billing period and tax wording from the catalogue.
  final String priceLabel;
  final List<String> features;
  final bool eligible;
  final String version;
  final bool recommended;
  final List<String> featureIds;
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
    this.storeId,
    this.currentPlanVersion,
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
  final String? storeId, currentPlanVersion;
}

/// Connects the original presentation to a session-owned read gateway. It never
/// writes a subscription, invokes billing or restores cached paid grants.
class GlobalAccountPlansConnected extends StatefulWidget {
  const GlobalAccountPlansConnected({
    required this.accountScope,
    required this.accountAuthenticated,
    required this.gateway,
    required this.onClose,
    this.storeId,
    this.storeName,
    this.clock,
    this.workspaceAccessConfirmed = false,
    this.workspaceOnly = false,
    this.workspaceGuide = GlobalWorkspacePlanGuide.unknown,
    this.applicationLabel,
    this.onOpenWorkspace,
    super.key,
  });
  final bool workspaceAccessConfirmed;
  final bool workspaceOnly;
  final GlobalWorkspacePlanGuide workspaceGuide;
  final String? applicationLabel;
  final VoidCallback? onOpenWorkspace;
  final Object? accountScope;
  final bool accountAuthenticated;
  final AccountPlansGateway? gateway;
  final VoidCallback onClose;
  final String? storeId, storeName;
  final DateTime Function()? clock;
  @override
  State<GlobalAccountPlansConnected> createState() =>
      _GlobalAccountPlansConnectedState();
}

class _GlobalAccountPlansConnectedState
    extends State<GlobalAccountPlansConnected>
    with WidgetsBindingObserver {
  GlobalAccountPlanAudience get _audience => widget.workspaceOnly
      ? GlobalAccountPlanAudience.business
      : GlobalAccountPlanAudience.personal;
  AccountPlansSnapshot? _snapshot;
  GlobalAccountPlansStatus _status = GlobalAccountPlansStatus.unavailable;
  int _attempt = 0;
  Timer? _expiry;
  Object get _binding => (
    widget.accountScope,
    widget.accountAuthenticated,
    widget.gateway,
    _audience,
    widget.storeId,
    widget.workspaceAccessConfirmed,
  );
  DateTime get _now => (widget.clock?.call() ?? DateTime.now()).toUtc();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(GlobalAccountPlansConnected oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountScope != widget.accountScope ||
        oldWidget.gateway != widget.gateway ||
        oldWidget.accountAuthenticated != widget.accountAuthenticated ||
        oldWidget.storeId != widget.storeId ||
        oldWidget.workspaceOnly != widget.workspaceOnly ||
        oldWidget.workspaceAccessConfirmed != widget.workspaceAccessConfirmed) {
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    } else {
      _attempt++;
      _expiry?.cancel();
      if (mounted)
        setState(() {
          _snapshot = null;
          _status = GlobalAccountPlansStatus.unavailable;
        });
    }
  }

  Future<void> _load() async {
    final generation = ++_attempt, binding = _binding;
    _expiry?.cancel();
    final gateway = widget.gateway;
    final scope = (
      audience: _audience == GlobalAccountPlanAudience.personal
          ? 'personal'
          : 'workspace',
      storeId: _audience == GlobalAccountPlanAudience.personal
          ? null
          : widget.storeId,
    );
    final available =
        widget.accountAuthenticated &&
        widget.accountScope != null &&
        gateway != null &&
        gateway.owner == widget.accountScope &&
        gateway.isCurrent() &&
        (scope.audience == 'personal' ||
            (scope.storeId != null && widget.workspaceAccessConfirmed));
    setState(() {
      _snapshot = null;
      _status = available
          ? GlobalAccountPlansStatus.loading
          : GlobalAccountPlansStatus.unavailable;
    });
    if (!available) return;
    try {
      final result = await gateway.read(scope, fresh: true);
      if (!mounted || generation != _attempt || binding != _binding) return;
      if (!gateway.isCurrent() ||
          result.scope != scope ||
          !result.validUntil.isAfter(_now)) {
        throw const AccountPlansFailure('stale_plans_response');
      }
      setState(() {
        _snapshot = result;
        _status = GlobalAccountPlansStatus.ready;
      });
      _expiry = Timer(result.validUntil.difference(_now), () {
        if (!mounted || generation != _attempt) return;
        // Drop confirmed state first; retry must read fresh authority.
        setState(() {
          _snapshot = null;
          _status = GlobalAccountPlansStatus.unavailable;
        });
      });
    } on Object {
      if (!mounted || generation != _attempt || binding != _binding) return;
      setState(() {
        _snapshot = null;
        _status = GlobalAccountPlansStatus.failed;
      });
    }
  }

  @override
  void dispose() {
    _attempt++;
    _expiry?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final owner = widget.accountScope;
    final subscription = snapshot?.subscription;
    final active =
        subscription != null &&
        {'active', 'cancelled'}.contains(subscription.state) &&
        !subscription.validFrom.isAfter(snapshot!.checkedAt) &&
        subscription.validUntil.isAfter(snapshot.checkedAt);
    String? label;
    if (subscription != null) {
      final end = subscription.validUntil;
      final date = '${end.day}/${end.month}/${end.year}';
      label =
          '${subscription.name} · ${switch (subscription.state) {
            'pending' => 'Activation pending',
            'revoked' => 'Access ended',
            'expired' => 'Expired',
            'cancelled' when active => 'Available until $date',
            'active' when active => 'Active until $date',
            _ => 'Expired',
          }}';
    }
    final data = owner == null
        ? null
        : GlobalAccountPlansViewData(
            accountScope: owner,
            revision: snapshot?.revision ?? 'unavailable',
            audience: _audience,
            status: _status,
            storeId: _audience == GlobalAccountPlanAudience.business
                ? widget.storeId
                : null,
            offers:
                snapshot?.offers
                    .map(
                      (offer) => GlobalAccountPlanOffer(
                        id: offer.id,
                        version: offer.version,
                        name: offer.name,
                        priceLabel: offer.priceLabel,
                        features: offer.features,
                        featureIds: offer.featureIds,
                        eligible: offer.eligible,
                        recommended: offer.recommended,
                      ),
                    )
                    .toList(growable: false) ??
                const [],
            currentPlanId: active ? subscription.planId : null,
            currentPlanVersion: active ? subscription.planVersion : null,
            subscriptionLabel: label,
          );
    return GlobalAccountPlansV2(
      accountScope: owner,
      accountAuthenticated: widget.accountAuthenticated,
      data: data,
      storeId: widget.storeId,
      storeName: widget.storeName,
      onClose: widget.onClose,
      workspaceAccessConfirmed: widget.workspaceAccessConfirmed,
      workspaceOnly: widget.workspaceOnly,
      workspaceGuide: widget.workspaceGuide,
      applicationLabel: widget.applicationLabel,
      onOpenWorkspace: widget.onOpenWorkspace,
      onRetry: _load,
    );
  }
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
    this.storeId,
    this.storeName,
    this.workspaceAccessConfirmed = false,
    this.workspaceOnly = false,
    this.workspaceGuide = GlobalWorkspacePlanGuide.unknown,
    this.applicationLabel,
    this.onOpenWorkspace,
    super.key,
  });
  final bool workspaceAccessConfirmed;
  final bool workspaceOnly;
  final GlobalWorkspacePlanGuide workspaceGuide;
  final String? applicationLabel;
  final VoidCallback? onOpenWorkspace;
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
  final String? storeId, storeName;

  @override
  State<GlobalAccountPlansV2> createState() => _GlobalAccountPlansV2State();
}

class _GlobalAccountPlansV2State extends State<GlobalAccountPlansV2> {
  GlobalAccountPlanAudience _audience = GlobalAccountPlanAudience.personal;
  bool _opening = false;
  String? _error;
  int _generation = 0;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    if (widget.workspaceOnly) _audience = GlobalAccountPlanAudience.business;
  }

  @override
  void didUpdateWidget(GlobalAccountPlansV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountScope != widget.accountScope ||
        oldWidget.accountAuthenticated != widget.accountAuthenticated ||
        oldWidget.data != widget.data ||
        oldWidget.storeId != widget.storeId ||
        oldWidget.workspaceOnly != widget.workspaceOnly ||
        oldWidget.workspaceGuide != widget.workspaceGuide ||
        oldWidget.workspaceAccessConfirmed != widget.workspaceAccessConfirmed) {
      _generation++;
      _opening = false;
      _error = null;
      _showAll = false;
      if (oldWidget.accountScope != widget.accountScope ||
          oldWidget.workspaceOnly != widget.workspaceOnly ||
          widget.workspaceGuide == GlobalWorkspacePlanGuide.approved) {
        _audience = widget.workspaceOnly
            ? GlobalAccountPlanAudience.business
            : GlobalAccountPlanAudience.personal;
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
        (_audience == GlobalAccountPlanAudience.business &&
            (!widget.workspaceAccessConfirmed ||
                widget.storeId == null ||
                data.storeId != widget.storeId)) ||
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
            (source.currentPlanId == offer.id &&
                (source.currentPlanVersion == null ||
                    source.currentPlanVersion == offer.version)))) {
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

  Widget _offerCard(
    GlobalAccountPlanOffer offer,
    GlobalAccountPlansViewData data,
    int generation,
  ) => Card(
    key: ValueKey('plan:${offer.id}:${offer.version}'),
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (offer.recommended)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Recommended',
                style: TextStyle(
                  color: Color(0xFF0000FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            offer.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(offer.priceLabel, style: const TextStyle(fontSize: 15)),
          for (final feature in offer.features)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(feature),
            ),
          const SizedBox(height: 12),
          if (offer.id == data.currentPlanId &&
              (data.currentPlanVersion == null ||
                  offer.version == data.currentPlanVersion))
            const Text('Current plan')
          else
            FilledButton(
              onPressed: !offer.eligible || _opening || widget.onReview == null
                  ? null
                  : () => _handoff(
                      data,
                      () async {
                        await widget.onReview?.call(offer, data.revision);
                      },
                      expectedGeneration: generation,
                      offer: offer,
                    ),
              child: const Text('Review plan'),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final guide =
        !widget.workspaceOnly &&
        _audience == GlobalAccountPlanAudience.business;
    final data = guide ? null : _data;
    final generation = _generation;
    final ready = data?.status == GlobalAccountPlansStatus.ready;
    final offers = ready
        ? <GlobalAccountPlanOffer>[
            ...data!.offers.where((offer) => offer.recommended),
            ...data.offers.where((offer) => !offer.recommended),
          ]
        : const <GlobalAccountPlanOffer>[];
    final visibleCount = _showAll ? offers.length : offers.length.clamp(0, 3);
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.workspaceOnly &&
            widget.workspaceGuide != GlobalWorkspacePlanGuide.approved)
          LayoutBuilder(
            builder: (context, constraints) {
              final style = Theme.of(context).textTheme.labelLarge!.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              );
              double labelWidth(String label) {
                final painter = TextPainter(
                  text: TextSpan(text: label, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final width = painter.width;
                painter.dispose();
                return width;
              }

              final stacked =
                  labelWidth('Personal') + labelWidth('Workspace') + 96 >
                  constraints.maxWidth;
              return SegmentedButton<GlobalAccountPlanAudience>(
                direction: stacked ? Axis.vertical : Axis.horizontal,
                style: SegmentedButton.styleFrom(
                  foregroundColor: const Color(0xFF23252B),
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: const Color(0xFF0000FF),
                  minimumSize: const Size.fromHeight(48),
                  textStyle: style,
                ),
                segments: const [
                  ButtonSegment(
                    value: GlobalAccountPlanAudience.personal,
                    label: Text('Personal'),
                  ),
                  ButtonSegment(
                    value: GlobalAccountPlanAudience.business,
                    label: Text('Workspace'),
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
                          _showAll = false;
                        });
                        widget.onAudienceChanged?.call(_audience);
                      },
              );
            },
          ),
        const SizedBox(height: 16),
        if (!guide &&
            widget.accountAuthenticated &&
            widget.accountScope != null &&
            (!widget.workspaceOnly ||
                (widget.workspaceAccessConfirmed && widget.storeId != null)))
          Card(
            key: const Key('account-free-access'),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Free · ₹0',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text('Included with your account'),
                  const SizedBox(height: 8),
                  Text(
                    widget.workspaceOnly
                        ? 'Free Workspace access'
                        : 'Shop and buy with your account',
                  ),
                ],
              ),
            ),
          ),
        if (widget.accountAuthenticated &&
            widget.accountScope != null &&
            _audience == GlobalAccountPlanAudience.business &&
            widget.storeId != null &&
            widget.storeName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Store · ${widget.storeName}',
              key: const Key('account-plan-store-context'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        if (!widget.accountAuthenticated)
          const Text('Sign in to view plans for your account.')
        else if (widget.accountScope == null)
          const Text('Plans are not available for this account right now.')
        else if (guide) ...[
          const Text(
            'Activate your Workspace',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            widget.applicationLabel ??
                (widget.workspaceGuide == GlobalWorkspacePlanGuide.available
                    ? 'Submit your business documents for MoolSocial approval.'
                    : 'Check your Workspace application or start registration.'),
          ),
          const SizedBox(height: 8),
          const Text(
            'After approval, use free Workspace access. Optional upgrades are available inside your Workspace.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.onOpenWorkspace,
            child: Text(
              widget.workspaceGuide == GlobalWorkspacePlanGuide.application
                  ? 'View application'
                  : widget.workspaceGuide == GlobalWorkspacePlanGuide.available
                  ? 'Activate Workspace'
                  : 'Check Workspace',
            ),
          ),
        ] else if (widget.workspaceOnly && widget.storeId == null)
          const Text(
            'Open an approved Store from My Workspaces to view its plans.',
          )
        else if (data?.status == GlobalAccountPlansStatus.loading)
          const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading plans'),
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
          if (offers.isEmpty)
            const Text('No plans are available for this account.'),
        ],
      ],
    );
    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ready && offers.length > 3)
          TextButton(
            key: const Key('account-plans-view-all'),
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll
                  ? 'Show fewer plans'
                  : 'View all plans (${offers.length})',
            ),
          ),
        if (ready && offers.isNotEmpty && widget.onReview == null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Plan changes are not available right now.',
              style: TextStyle(fontSize: 13, color: Color(0xFF666A73)),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!),
          ),
        if (guide && widget.accountAuthenticated) ...[
          const SizedBox(height: 16),
          const Text(
            'Workspace activation requires documents and MoolSocial approval.',
            style: TextStyle(color: Color(0xFF666A73), fontSize: 13),
          ),
        ],
      ],
    );
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
            child: ListView.builder(
              key: const Key('account-plans-list'),
              padding: const EdgeInsets.all(16),
              itemCount: visibleCount + 2,
              itemBuilder: (context, index) {
                if (index == 0) return header;
                if (index == visibleCount + 1) return footer;
                return _offerCard(offers[index - 1], data!, generation);
              },
            ),
          ),
        ),
      ),
    );
  }
}
