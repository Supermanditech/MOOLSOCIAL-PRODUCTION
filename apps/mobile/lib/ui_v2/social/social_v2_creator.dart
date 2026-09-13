import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/creator/creator_models.dart';
import '../../features/creator/creator_session.dart';
import 'social_v2_design.dart';
import 'social_v2_youtube_connect.dart';

enum CreatorSocialV2Owner {
  home,
  publish,
  library,
  performance,
  audience,
  campaigns,
  earnings,
  safety,
  memberships,
}

enum _CreatorPublishView {
  composer,
  destinations,
  preview,
  publishing,
  partial,
  success,
}

class CreatorSocialV2Screen extends StatefulWidget {
  const CreatorSocialV2Screen({
    required this.session,
    required this.owner,
    this.initialState,
    super.key,
  });

  final CreatorSession session;
  final CreatorSocialV2Owner owner;
  final String? initialState;

  @override
  State<CreatorSocialV2Screen> createState() => _CreatorSocialV2ScreenState();
}

class _CreatorSocialV2ScreenState extends State<CreatorSocialV2Screen> {
  late CreatorSocialV2Owner _owner = widget.owner;
  late _CreatorPublishView _publishView;
  late bool _youtubeDestination;
  late bool _showWorkspaceActivation;

  static _CreatorPublishView _publishViewFor(String? state) => switch (state) {
    'destinations' => _CreatorPublishView.destinations,
    'preview' => _CreatorPublishView.preview,
    'publishing' => _CreatorPublishView.publishing,
    'partial' => _CreatorPublishView.partial,
    'success' => _CreatorPublishView.success,
    _ => _CreatorPublishView.composer,
  };

  @override
  void initState() {
    super.initState();
    _youtubeDestination = widget.session.youtubeChannelConnected;
    _showWorkspaceActivation =
        widget.initialState == 'activate' ||
        !widget.session.creatorWorkspaceActive;
    _publishView = _publishViewFor(widget.initialState);
  }

  @override
  void didUpdateWidget(covariant CreatorSocialV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner ||
        oldWidget.initialState != widget.initialState) {
      _owner = widget.owner;
      _publishView = _publishViewFor(widget.initialState);
      _showWorkspaceActivation =
          widget.initialState == 'activate' ||
          !widget.session.creatorWorkspaceActive;
      _youtubeDestination = widget.session.youtubeChannelConnected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        _showOwnerMessage();
        final (title, subtitle) = switch (_owner) {
          CreatorSocialV2Owner.home => (
            'Creator Studio',
            'Create, distribute and earn from attributable outcomes',
          ),
          CreatorSocialV2Owner.publish => (
            'Create & Publish',
            'Prepare once and check each destination',
          ),
          CreatorSocialV2Owner.library => (
            'Content Library',
            'Drafts, scheduled, published and failed content',
          ),
          CreatorSocialV2Owner.performance => (
            'Performance',
            'Content reach and attributable MoolSocial outcomes',
          ),
          CreatorSocialV2Owner.audience => (
            'Audience',
            'Understand your MoolSocial community',
          ),
          CreatorSocialV2Owner.campaigns => (
            'Campaigns',
            'Choose funded work with requirements shown first',
          ),
          CreatorSocialV2Owner.earnings => (
            'Earnings',
            'Delivered-order attribution and payable balance',
          ),
          CreatorSocialV2Owner.safety => (
            'Rights & Safety',
            'Verification, disclosures, moderation and appeals',
          ),
          CreatorSocialV2Owner.memberships => (
            'Creator Memberships',
            'Follower-paid benefits managed separately',
          ),
        };
        return SocialV2Scaffold(
          title: title,
          subtitle: subtitle,
          selectedTab: SocialV2Tab.create,
          onBack: () => Navigator.of(context).pop(),
          onTab: (_) {},
          bottomRail: _CreatorBottomRail(
            owner: _owner,
            onSelected: _selectOwner,
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(
              key: ValueKey(
                '${_owner.name}-${_publishView.name}-$_showWorkspaceActivation',
              ),
              child: _buildOwner(),
            ),
          ),
        );
      },
    );
  }

  void _showOwnerMessage() {
    final message = widget.session.errorMessage ?? widget.session.noticeMessage;
    if (message == null || message.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showSocialV2Message(context, _customerMessage(message));
      widget.session.clearMessages();
    });
  }

  String _customerMessage(String message) {
    if (message.contains('Review it and retry')) {
      return 'Publishing did not finish. Your content is saved and ready to retry.';
    }
    if (message.contains('review')) {
      return message
          .replaceAll('Review', 'Check')
          .replaceAll('review', 'check');
    }
    return message;
  }

  void _selectOwner(CreatorSocialV2Owner owner) {
    if (!widget.session.creatorWorkspaceActive) {
      setState(() {
        _owner = CreatorSocialV2Owner.home;
        _showWorkspaceActivation = true;
      });
      return;
    }
    setState(() {
      _owner = owner;
      _showWorkspaceActivation = false;
      if (owner != CreatorSocialV2Owner.publish) {
        _publishView = _CreatorPublishView.composer;
      }
    });
  }

  Widget _buildOwner() {
    if (_showWorkspaceActivation) return _workspaceActivation();
    return switch (_owner) {
      CreatorSocialV2Owner.home => _home(),
      CreatorSocialV2Owner.publish => _publish(),
      CreatorSocialV2Owner.library => _library(),
      CreatorSocialV2Owner.performance => _performance(),
      CreatorSocialV2Owner.audience => _audience(),
      CreatorSocialV2Owner.campaigns => _campaigns(),
      CreatorSocialV2Owner.earnings => _earnings(),
      CreatorSocialV2Owner.safety => _safety(),
      CreatorSocialV2Owner.memberships => _memberships(),
    };
  }

  Widget _home() {
    return SocialV2PageList(
      children: [
        const SocialV2Hero(
          eyebrow: 'Your creator workspace',
          title:
              'Create once. Reach the right audience. Earn from verified outcomes.',
          detail: 'Your personal MoolSocial identity remains unchanged.',
        ),
        const SocialV2Notice(
          title: 'Creator workspace active',
          detail:
              'Identity verified · YouTube publishing connection remains optional',
        ),
        _OwnerGrid(
          items: [
            (
              'Create & Publish',
              'Prepare content and check each destination',
              CreatorSocialV2Owner.publish,
            ),
            (
              'Content Library',
              'Drafts, scheduled, published and failed',
              CreatorSocialV2Owner.library,
            ),
            (
              'Campaigns',
              'Find funded work with terms shown first',
              CreatorSocialV2Owner.campaigns,
            ),
            (
              'Performance',
              'Reach, orders and attributable outcomes',
              CreatorSocialV2Owner.performance,
            ),
          ],
          onTap: _selectOwner,
        ),
        const SocialV2SectionTitle(
          'Today',
          detail: 'Actions that need your attention',
        ),
        SocialV2ListTile(
          icon: Icons.campaign_outlined,
          title: 'Local grocery campaign',
          detail: '₹3,500 funded · Reel due 25 July',
          badge: 'Best fit',
          onTap: () => _selectOwner(CreatorSocialV2Owner.campaigns),
        ),
        SocialV2ListTile(
          icon: Icons.account_balance_wallet_outlined,
          title: '₹6,240 available for payout',
          detail: 'Delivered orders verified after returns',
          onTap: () => _selectOwner(CreatorSocialV2Owner.earnings),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectOwner(CreatorSocialV2Owner.audience),
                child: const Text('Audience'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _selectOwner(CreatorSocialV2Owner.safety),
                child: const Text('Rights & Safety'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _workspaceActivation() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-creator-activation'),
      children: [
        const SocialV2Hero(
          eyebrow: 'One MoolSocial account',
          title: 'Add Creator tools to your existing profile',
          detail:
              'Your followers, purchases, saved content and identity stay together.',
        ),
        const SocialV2ListTile(
          icon: Icons.person_outline_rounded,
          title: 'Confirm your public profile',
          detail: 'Name, handle and profile image',
          badge: '1',
        ),
        const SocialV2ListTile(
          icon: Icons.video_library_outlined,
          title: 'Choose what you create',
          detail: 'Reels, posts, carousels or video on a connected service',
          badge: '2',
        ),
        const SocialV2ListTile(
          icon: Icons.verified_user_outlined,
          title: 'Complete required verification',
          detail: 'Identity, rights and payout details when applicable',
          badge: '3',
        ),
        FilledButton(
          key: const Key('social-v2-activate-creator-workspace'),
          onPressed: () {
            widget.session.activateCreatorWorkspace();
            setState(() => _showWorkspaceActivation = false);
          },
          child: const Text('Add Creator workspace'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Not now'),
        ),
      ],
    );
  }

  Widget _publish() {
    return switch (_publishView) {
      _CreatorPublishView.composer => _PublishComposer(
        session: widget.session,
        onContinue: _continuePublish,
      ),
      _CreatorPublishView.destinations => _publishDestinations(),
      _CreatorPublishView.preview => _publishConfirmation(),
      _CreatorPublishView.publishing => _distributionProgress(),
      _CreatorPublishView.partial => _distributionPartial(),
      _CreatorPublishView.success => _distributionSuccess(),
    };
  }

  void _continuePublish() {
    if (widget.session.publishFormat == CreatorPublishFormat.youtube) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SocialYouTubeConnectV2Screen(session: widget.session),
        ),
      );
      return;
    }
    setState(() => _publishView = _CreatorPublishView.destinations);
  }

  Widget _publishDestinations() {
    return SocialV2PageList(
      children: [
        const SocialV2SectionTitle(
          'Where should this content go?',
          detail: 'Requirements appear before you continue',
        ),
        const SocialV2ListTile(
          icon: Icons.grid_view_rounded,
          title: 'MoolSocial',
          detail: 'Ready · product destination attached',
          badge: 'Required',
        ),
        SocialV2ListTile(
          icon: Icons.ondemand_video_outlined,
          title: 'YouTube channel',
          detail: widget.session.youtubeChannelConnected
              ? 'Connected · title, description and privacy required'
              : 'Connect an eligible channel before publishing',
          badge: _youtubeDestination
              ? 'Selected'
              : widget.session.youtubeChannelConnected
              ? 'Available'
              : 'Connect',
          onTap: () {
            if (!widget.session.youtubeChannelConnected) {
              showSocialV2Message(
                context,
                'Connect an eligible YouTube channel before selecting it.',
              );
              return;
            }
            setState(() => _youtubeDestination = !_youtubeDestination);
          },
        ),
        SocialV2ListTile(
          icon: Icons.camera_alt_outlined,
          title: 'Instagram Professional',
          detail: 'Eligible Business or Creator account required',
          badge: 'Connect',
          onTap: () => showSocialV2Message(
            context,
            'Choose an eligible Instagram Professional account',
          ),
        ),
        SocialV2ListTile(
          icon: Icons.people_outline_rounded,
          title: 'Facebook Page',
          detail: 'Choose a Page you are authorized to manage',
          badge: 'Connect',
          onTap: () =>
              showSocialV2Message(context, 'Choose a Facebook Page you manage'),
        ),
        FilledButton(
          key: const Key('social-v2-publish-destinations'),
          onPressed: () =>
              setState(() => _publishView = _CreatorPublishView.preview),
          child: Text(
            _youtubeDestination
                ? 'Check MoolSocial and YouTube'
                : 'Check MoolSocial',
          ),
        ),
        OutlinedButton(
          onPressed: () =>
              setState(() => _publishView = _CreatorPublishView.composer),
          child: const Text('Back to content'),
        ),
      ],
    );
  }

  Widget _publishConfirmation() {
    return SocialV2PageList(
      children: [
        const SocialV2SectionTitle(
          'Check before publishing',
          detail: 'Each destination keeps its own requirements',
        ),
        const SocialV2Notice(
          title: 'MoolSocial content ready',
          detail: 'Everyone · product destination attached',
        ),
        if (_youtubeDestination)
          const SocialV2Notice(
            title: 'YouTube destination ready',
            detail: 'Private until YouTube finishes processing',
          ),
        if (_youtubeDestination)
          const SocialV2Notice(
            title: 'Each destination publishes independently',
            detail:
                'A failure on one destination will not duplicate a successful publication.',
            warning: true,
          ),
        FilledButton(
          key: const Key('social-v2-confirm-publish'),
          onPressed: () =>
              setState(() => _publishView = _CreatorPublishView.publishing),
          child: Text(
            _youtubeDestination
                ? 'Publish to 2 destinations'
                : 'Publish to MoolSocial',
          ),
        ),
        OutlinedButton(
          onPressed: () =>
              setState(() => _publishView = _CreatorPublishView.destinations),
          child: const Text('Back to destinations'),
        ),
      ],
    );
  }

  Widget _distributionProgress() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-publishing-progress'),
      children: [
        const SocialV2SectionTitle(
          'Publishing',
          detail: 'Progress stays with your account if you leave this screen',
        ),
        const SocialV2Notice(
          title: 'MoolSocial',
          detail: 'Ready to publish without creating a duplicate',
        ),
        if (_youtubeDestination)
          const SocialV2Notice(
            title: 'YouTube',
            detail: 'The connected destination will be checked separately',
            warning: true,
          ),
        FilledButton(
          key: const Key('social-v2-check-publish-result'),
          onPressed: _completePublish,
          child: const Text('Check result'),
        ),
        OutlinedButton(
          onPressed: () => _selectOwner(CreatorSocialV2Owner.library),
          child: const Text('Open Content Library'),
        ),
      ],
    );
  }

  Future<void> _completePublish() async {
    final ok = await widget.session.publishNativePost();
    if (!mounted) return;
    if (!ok) {
      setState(() => _publishView = _CreatorPublishView.partial);
      return;
    }
    setState(
      () => _publishView = _youtubeDestination
          ? _CreatorPublishView.partial
          : _CreatorPublishView.success,
    );
  }

  Widget _distributionPartial() {
    final nativePublished = widget.session.publishedPostId != null;
    return SocialV2PageList(
      key: const ValueKey('social-v2-publishing-partial'),
      children: [
        SocialV2Notice(
          title: nativePublished
              ? 'Published on MoolSocial'
              : 'Your content is still saved',
          detail: nativePublished
              ? 'The same content will not be posted twice.'
              : 'Publishing did not finish and no duplicate was created.',
          warning: !nativePublished,
        ),
        if (_youtubeDestination)
          const SocialV2Notice(
            title: 'YouTube needs attention',
            detail:
                'The destination did not finish. Your content and destination choices remain saved.',
            warning: true,
          ),
        FilledButton(
          key: const Key('social-v2-retry-publishing'),
          onPressed: () => setState(
            () => _publishView = nativePublished
                ? _CreatorPublishView.success
                : _CreatorPublishView.publishing,
          ),
          child: Text(
            nativePublished ? 'Keep MoolSocial result' : 'Try publishing again',
          ),
        ),
        if (!nativePublished)
          OutlinedButton(
            key: const Key('social-v2-review-publish-content'),
            onPressed: () =>
                setState(() => _publishView = _CreatorPublishView.composer),
            child: const Text('Review content'),
          ),
        OutlinedButton(
          onPressed: () => _selectOwner(CreatorSocialV2Owner.library),
          child: const Text('Open Content Library'),
        ),
      ],
    );
  }

  Widget _distributionSuccess() {
    return SocialV2PageList(
      key: const ValueKey('social-v2-publishing-success'),
      children: [
        const SocialV2Hero(
          eyebrow: 'Published',
          title: 'Your content is ready for its audience',
          detail:
              'MoolSocial records each destination result so the same content is not published twice.',
        ),
        const SocialV2Notice(
          title: 'MoolSocial published',
          detail: 'Performance appears as eligible activity is recorded.',
        ),
        FilledButton(
          onPressed: () => _selectOwner(CreatorSocialV2Owner.library),
          child: const Text('Open Content Library'),
        ),
        OutlinedButton(
          onPressed: () => _selectOwner(CreatorSocialV2Owner.performance),
          child: const Text('View Performance'),
        ),
      ],
    );
  }

  Widget _library() {
    final session = widget.session;
    return SocialV2PageList(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<CreatorContentTab>(
            segments: const [
              ButtonSegment(
                value: CreatorContentTab.published,
                label: Text('Published'),
              ),
              ButtonSegment(
                value: CreatorContentTab.drafts,
                label: Text('Drafts'),
              ),
              ButtonSegment(
                value: CreatorContentTab.scheduled,
                label: Text('Scheduled'),
              ),
              ButtonSegment(
                value: CreatorContentTab.unavailable,
                label: Text('Needs attention'),
              ),
            ],
            selected: {session.contentTab},
            onSelectionChanged: (values) => session.setContentTab(values.first),
          ),
        ),
        if (session.visibleContent.isEmpty)
          const SocialV2Notice(
            title: 'No content here yet',
            detail: 'Choose another status or create content.',
            warning: true,
          ),
        for (final content in session.visibleContent)
          SocialV2ListTile(
            icon: content.youtube
                ? Icons.ondemand_video_outlined
                : Icons.play_circle_outline_rounded,
            title: content.title,
            detail: '${content.format} · ${content.detail}',
            badge: content.status,
            onTap: () {
              session.selectContent(content.id);
              showSocialV2Message(context, '${content.title} selected');
            },
          ),
        FilledButton(
          onPressed: () => _selectOwner(CreatorSocialV2Owner.publish),
          child: const Text('Create content'),
        ),
      ],
    );
  }

  Widget _performance() {
    final session = widget.session;
    final values = switch (session.performanceWindow) {
      CreatorPerformanceWindow.sevenDays => ('14.8K', '36K', '42', '₹980'),
      CreatorPerformanceWindow.twentyEightDays => (
        '48.2K',
        '126K',
        '126',
        '₹2,840',
      ),
      CreatorPerformanceWindow.ninetyDays => ('142K', '410K', '384', '₹8,760'),
    };
    return SocialV2PageList(
      children: [
        SegmentedButton<CreatorPerformanceWindow>(
          segments: const [
            ButtonSegment(
              value: CreatorPerformanceWindow.sevenDays,
              label: Text('7 days'),
            ),
            ButtonSegment(
              value: CreatorPerformanceWindow.twentyEightDays,
              label: Text('28 days'),
            ),
            ButtonSegment(
              value: CreatorPerformanceWindow.ninetyDays,
              label: Text('90 days'),
            ),
          ],
          selected: {session.performanceWindow},
          onSelectionChanged: (values) =>
              session.setPerformanceWindow(values.first),
        ),
        _MetricGrid(
          values: [
            ('MoolSocial reach', values.$1, 'Eligible Social impressions'),
            ('External reach', values.$2, 'Connected account reports'),
            ('Delivered orders', values.$3, 'Returns removed'),
            ('Payable', values.$4, 'Attributable delivered orders'),
          ],
        ),
        SocialV2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How local baskets save time',
                style: TextStyle(
                  color: SocialV2Colors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: .72,
                color: SocialV2Colors.green,
                backgroundColor: SocialV2Colors.canvas,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 10),
              Text(
                '${values.$1} MoolSocial reach · ${values.$3} delivered orders · ${values.$4} payable',
                style: const TextStyle(
                  color: SocialV2Colors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              OutlinedButton(
                onPressed: () => showSocialV2Message(
                  context,
                  'Order-line attribution is ready',
                ),
                child: const Text('View attribution'),
              ),
            ],
          ),
        ),
        const SocialV2Notice(
          title: 'Connected account insights explain content performance',
          detail:
              'MoolSocial order-line attribution controls creator commission.',
        ),
      ],
    );
  }

  Widget _audience() {
    return SocialV2PageList(
      children: [
        const _MetricGrid(
          values: [
            ('Followers', '84.2K', 'MoolSocial followers'),
            ('Returning', '62%', 'Viewed again in 28 days'),
          ],
        ),
        SocialV2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SocialV2SectionTitle('Top MoolSocial interests'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  'Local commerce',
                  'Food',
                  'Small business',
                  'Jodhpur',
                ].map((label) => Chip(label: Text(label))).toList(),
              ),
            ],
          ),
        ),
        const SocialV2ListTile(
          icon: Icons.schedule_outlined,
          title: 'Active audience times',
          detail: '7–9 AM · 1–2 PM · 7–10 PM',
        ),
        OutlinedButton(
          onPressed: () =>
              showSocialV2Message(context, 'Audience summary prepared'),
          child: const Text('Prepare audience summary'),
        ),
        FilledButton(
          onPressed: () => _selectOwner(CreatorSocialV2Owner.memberships),
          child: const Text('Creator Memberships'),
        ),
      ],
    );
  }

  Widget _campaigns() {
    final session = widget.session;
    return SocialV2PageList(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<CreatorCampaignTab>(
            segments: const [
              ButtonSegment(
                value: CreatorCampaignTab.bestFit,
                label: Text('Best Fit'),
              ),
              ButtonSegment(
                value: CreatorCampaignTab.awareness,
                label: Text('Awareness'),
              ),
              ButtonSegment(
                value: CreatorCampaignTab.conversion,
                label: Text('Sales'),
              ),
              ButtonSegment(
                value: CreatorCampaignTab.saved,
                label: Text('Saved'),
              ),
            ],
            selected: {session.campaignTab},
            onSelectionChanged: (values) =>
                session.setCampaignTab(values.first),
          ),
        ),
        for (final campaign in reviewCreatorCampaigns)
          SocialV2ListTile(
            icon: Icons.campaign_outlined,
            title: campaign.title,
            detail:
                '${campaign.sponsor} · ${campaign.format} · ₹${campaign.fixedPay} fixed',
            badge: '${campaign.fit}% fit',
            onTap: () {
              session.selectCampaign(campaign.id);
              _openCampaignTerms();
            },
          ),
      ],
    );
  }

  void _openCampaignTerms() {
    final campaign = widget.session.selectedCampaign;
    showSocialV2Sheet(
      context,
      title: campaign.title,
      subtitle: 'Read every requirement before accepting',
      children: [
        SocialV2Notice(
          title: campaign.sponsor,
          detail: '${campaign.format} · ${campaign.deadline}',
        ),
        Text(
          '• ${campaign.format}\n• ${campaign.geography}\n• ${campaign.disclosure}\n• ${campaign.outcomePay}\n• ${campaign.attribution} attribution window',
          style: const TextStyle(
            color: SocialV2Colors.ink,
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        CheckboxListTile(
          value: widget.session.campaignTermsAccepted,
          onChanged: (value) =>
              widget.session.acceptCampaignTerms(value ?? false),
          title: const Text('I accept these requirements'),
          subtitle: const Text(
            'Content rights, disclosure, deadline and payment terms are understood.',
          ),
        ),
        FilledButton(
          key: const Key('social-v2-accept-campaign'),
          onPressed: () async {
            final ok = await widget.session.acceptCampaign();
            if (!mounted || !ok) return;
            Navigator.of(context).pop();
            showSocialV2Message(
              context,
              'Campaign added to your Creator workspace',
            );
          },
          child: const Text('Accept campaign'),
        ),
      ],
    );
  }

  Widget _earnings() {
    return SocialV2PageList(
      children: [
        const SocialV2Hero(
          eyebrow: 'Available for payout',
          title: '₹6,240',
          detail: 'Verified bank account · automatic payout on 25 July',
        ),
        const _MetricGrid(
          values: [
            ('Pending', '₹2,180', 'Inside return window'),
            ('Paid', '₹18,420', 'Current financial year'),
          ],
        ),
        const SocialV2SectionTitle(
          'Recent earnings',
          detail: 'Every amount has a traceable source',
        ),
        for (final item in reviewCreatorLedger)
          SocialV2ListTile(
            icon: Icons.account_balance_wallet_outlined,
            title: item.title,
            detail: item.detail,
            badge: item.amount,
            onTap: () => widget.session.selectLedger(item.id),
          ),
        FilledButton(
          onPressed: widget.session.busy
              ? null
              : widget.session.prepareStatement,
          child: const Text('Prepare statement'),
        ),
      ],
    );
  }

  Widget _safety() {
    return SocialV2PageList(
      children: [
        const SocialV2Notice(
          title: 'Identity verified',
          detail: 'Creator workspace · verification checked 20 July 2026',
        ),
        SocialV2ListTile(
          icon: Icons.shield_outlined,
          title: 'Content rights',
          detail: 'Declare ownership, licence or permitted use',
          onTap: () => widget.session.selectControl(CreatorControlArea.rights),
        ),
        SocialV2ListTile(
          icon: Icons.campaign_outlined,
          title: 'Sponsored disclosures',
          detail: 'Required labels and campaign usage terms',
          onTap: () =>
              widget.session.selectControl(CreatorControlArea.disclosure),
        ),
        SocialV2ListTile(
          icon: Icons.people_outline,
          title: 'Team access',
          detail: 'Editor, analyst and campaign roles',
          onTap: () => widget.session.selectControl(CreatorControlArea.team),
        ),
        SocialV2ListTile(
          icon: Icons.gavel_outlined,
          title: 'Moderation and appeals',
          detail: 'Decisions, reasons, evidence and appeal path',
          onTap: () => _openAppeal(),
        ),
        SocialV2ListTile(
          icon: Icons.settings_outlined,
          title: 'Connected channels',
          detail: 'Check permissions and disconnect safely',
          onTap: () => showSocialV2Message(
            context,
            'Connected-channel permissions are ready',
          ),
        ),
      ],
    );
  }

  void _openAppeal() {
    final controller = TextEditingController(text: widget.session.appealNote);
    showSocialV2Sheet(
      context,
      title: 'Submit an appeal',
      subtitle: 'Explain the evidence clearly',
      children: [
        TextField(
          key: const Key('social-creator-appeal-input'),
          controller: controller,
          minLines: 3,
          maxLines: 6,
          scrollPadding: socialV2InputScrollPadding,
          textInputAction: TextInputAction.done,
          onEditingComplete: () => FocusScope.of(context).unfocus(),
          decoration: const InputDecoration(
            labelText: 'Evidence and explanation',
          ),
          onChanged: widget.session.setAppealNote,
        ),
        CheckboxListTile(
          value: widget.session.appealEvidenceConfirmed,
          onChanged: (value) =>
              widget.session.confirmAppealEvidence(value ?? false),
          title: const Text('I can provide this evidence'),
        ),
        FilledButton(
          onPressed: widget.session.submitAppeal,
          child: const Text('Submit appeal'),
        ),
      ],
    );
  }

  Widget _memberships() {
    return SocialV2PageList(
      children: [
        const SocialV2Notice(
          title: 'Follower-paid Creator Memberships',
          detail:
              'This is separate from Creator Pro and other MoolSocial product plans.',
          warning: true,
        ),
        for (final plan in reviewCreatorMembershipPlans)
          SocialV2ListTile(
            icon: Icons.workspace_premium_outlined,
            title: plan.name,
            detail: '₹${plan.monthlyPrice}/month · ${plan.promise}',
            badge: widget.session.selectedMembershipId == plan.id
                ? 'Selected'
                : 'Choose',
            onTap: () => widget.session.selectMembership(plan.id),
          ),
        CheckboxListTile(
          value: widget.session.membershipBenefitsConfirmed,
          onChanged: (value) =>
              widget.session.confirmMembershipBenefits(value ?? false),
          title: const Text('The member promise is accurate'),
        ),
        CheckboxListTile(
          value: widget.session.membershipBillingConfirmed,
          onChanged: (value) =>
              widget.session.confirmMembershipBilling(value ?? false),
          title: const Text(
            'Price, renewal, refund and cancellation terms are clear',
          ),
        ),
        FilledButton(
          onPressed: widget.session.busy
              ? null
              : widget.session.saveMembershipPlan,
          child: const Text('Save membership plan'),
        ),
      ],
    );
  }
}

class _CreatorBottomRail extends StatelessWidget {
  const _CreatorBottomRail({required this.owner, required this.onSelected});
  final CreatorSocialV2Owner owner;
  final ValueChanged<CreatorSocialV2Owner> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(CreatorSocialV2Owner, String, IconData)>[
      (
        CreatorSocialV2Owner.publish,
        'Create',
        Icons.add_circle_outline_rounded,
      ),
      (CreatorSocialV2Owner.home, 'Studio', Icons.home_outlined),
      (CreatorSocialV2Owner.campaigns, 'Campaigns', Icons.campaign_outlined),
      (
        CreatorSocialV2Owner.earnings,
        'Earnings',
        Icons.account_balance_wallet_outlined,
      ),
    ];
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: SocialV2Colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CreatorRailItem(
              active: false,
              label: 'Mool',
              icon: Icons.grid_view_rounded,
              onTap: () {
                final router = GoRouter.of(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
                router.go('/app/mool');
              },
            ),
          ),
          for (final item in items)
            Expanded(
              child: _CreatorRailItem(
                active: owner == item.$1,
                label: item.$2,
                icon: item.$3,
                onTap: () => onSelected(item.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreatorRailItem extends StatelessWidget {
  const _CreatorRailItem({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final bool active;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          decoration: BoxDecoration(
            color: active ? SocialV2Colors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: active ? Colors.white : SocialV2Colors.muted,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: active ? Colors.white : SocialV2Colors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerGrid extends StatelessWidget {
  const _OwnerGrid({required this.items, required this.onTap});
  final List<(String, String, CreatorSocialV2Owner)> items;
  final ValueChanged<CreatorSocialV2Owner> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.5,
      children: items
          .map(
            (item) => SocialV2Card(
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => onTap(item.$3),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: SocialV2Colors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$2,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SocialV2Colors.muted,
                          fontSize: 10,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _PublishComposer extends StatefulWidget {
  const _PublishComposer({required this.session, required this.onContinue});
  final CreatorSession session;
  final VoidCallback onContinue;
  @override
  State<_PublishComposer> createState() => _PublishComposerState();
}

class _PublishComposerState extends State<_PublishComposer> {
  late final _title = TextEditingController(
    text: widget.session.postTitle.isEmpty
        ? 'Fresh produce packed for a Jodhpur morning'
        : widget.session.postTitle,
  );
  late final _caption = TextEditingController(
    text: widget.session.postCaption.isEmpty
        ? 'Fresh produce packed by a verified local shop.'
        : widget.session.postCaption,
  );

  @override
  void dispose() {
    _title.dispose();
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return SocialV2PageList(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<CreatorPublishFormat>(
            segments: const [
              ButtonSegment(
                value: CreatorPublishFormat.reel,
                label: Text('Reel'),
              ),
              ButtonSegment(
                value: CreatorPublishFormat.youtube,
                label: Text('Video'),
              ),
              ButtonSegment(
                value: CreatorPublishFormat.text,
                label: Text('Post'),
              ),
              ButtonSegment(
                value: CreatorPublishFormat.image,
                label: Text('Carousel'),
              ),
            ],
            selected: {session.publishFormat},
            onSelectionChanged: (values) =>
                session.selectPublishFormat(values.first),
          ),
        ),
        SocialV2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => session.selectMedia(),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => session.selectMedia(),
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              if (session.mediaSelected)
                const SocialV2Notice(
                  title: 'Media selected',
                  detail: 'Ready for title, caption and destination',
                ),
              TextField(
                key: const Key('social-creator-publish-title'),
                controller: _title,
                scrollPadding: socialV2InputScrollPadding,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: session.setPostTitle,
              ),
              const SizedBox(height: 9),
              TextField(
                key: const Key('social-creator-publish-caption'),
                controller: _caption,
                minLines: 3,
                maxLines: 6,
                scrollPadding: socialV2InputScrollPadding,
                textInputAction: TextInputAction.done,
                onEditingComplete: () => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(labelText: 'Caption'),
                onChanged: session.setPostCaption,
              ),
              CheckboxListTile(
                value: session.rightsConfirmed,
                onChanged: (value) => session.confirmRights(value ?? false),
                title: const Text('I have the right to publish this content'),
              ),
              if (session.publishFormat == CreatorPublishFormat.reel)
                CheckboxListTile(
                  value: session.reelFundingReviewed,
                  onChanged: (value) =>
                      session.acceptReelFunding(value ?? false),
                  title: const Text(
                    'Sponsor, run period and expiry are correct',
                  ),
                ),
              FilledButton(
                key: const Key('social-v2-choose-destinations'),
                onPressed: () {
                  session
                    ..setPostTitle(_title.text)
                    ..setPostCaption(_caption.text);
                  if (session.publishFormat == CreatorPublishFormat.youtube) {
                    widget.onContinue();
                    return;
                  }
                  if (!session.mediaSelected &&
                      session.publishFormat != CreatorPublishFormat.text) {
                    showSocialV2Message(
                      context,
                      'Choose media before continuing',
                    );
                    return;
                  }
                  widget.onContinue();
                },
                child: Text(
                  session.publishFormat == CreatorPublishFormat.youtube
                      ? 'Connect a YouTube video'
                      : 'Choose publishing destinations',
                ),
              ),
              OutlinedButton(
                onPressed: session.saveDraft,
                child: const Text('Save Draft'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.values});
  final List<(String, String, String)> values;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: .75,
      children: values
          .map(
            (value) => SocialV2Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.$1.toUpperCase(),
                    style: const TextStyle(
                      color: SocialV2Colors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value.$2,
                    style: const TextStyle(
                      color: SocialV2Colors.navy,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    value.$3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SocialV2Colors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
