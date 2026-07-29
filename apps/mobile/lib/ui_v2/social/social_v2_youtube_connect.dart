import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/creator/creator_models.dart';
import '../../features/creator/creator_session.dart';
import 'social_v2_design.dart';

final Expando<String> _activeYouTubeConnectReturnMessages = Expando<String>(
  'activeYouTubeConnectReturnMessages',
);

class SocialYouTubeConnectV2Screen extends StatefulWidget {
  const SocialYouTubeConnectV2Screen({
    required this.session,
    this.youtubeConnectResult,
    super.key,
  });

  final CreatorSession session;
  final String? youtubeConnectResult;

  @override
  State<SocialYouTubeConnectV2Screen> createState() =>
      _SocialYouTubeConnectV2ScreenState();
}

class _SocialYouTubeConnectV2ScreenState
    extends State<SocialYouTubeConnectV2Screen> {
  static const _connectedMessage =
      'YouTube is connected to your MoolSocial account. '
      'You can now use eligible YouTube videos and Shorts in MoolSocial.';
  static const _notConnectedMessage =
      'YouTube was not connected. Try again or choose another Google account.';

  late final TextEditingController _url = TextEditingController(
    text: widget.session.youtubeUrl,
  );
  late final TextEditingController _context = TextEditingController(
    text: widget.session.youtubeContext,
  );
  String? _handledReturnResult;
  String? _returnMessage;

  @override
  void initState() {
    super.initState();
    _scheduleReturnMessage(widget.youtubeConnectResult);
  }

  @override
  void didUpdateWidget(covariant SocialYouTubeConnectV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeConnectResult != widget.youtubeConnectResult) {
      _scheduleReturnMessage(widget.youtubeConnectResult);
    }
  }

  void _scheduleReturnMessage(String? result) {
    if ((result != 'complete' && result != 'failed') ||
        result == _handledReturnResult ||
        _activeYouTubeConnectReturnMessages[widget.session] == result) {
      return;
    }
    _handledReturnResult = result;
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (_activeYouTubeConnectReturnMessages[widget.session] == result) {
        return;
      }
      _activeYouTubeConnectReturnMessages[widget.session] = result;
      // This return value controls presentation only. Authoritative YouTube
      // connection state remains on the backend.
      setState(() {
        _returnMessage = result == 'complete'
            ? _connectedMessage
            : _notConnectedMessage;
      });
      Future<void>.delayed(const Duration(seconds: 5), () {
        if (mounted && _handledReturnResult == result) {
          setState(() {
            _returnMessage = null;
          });
        }
        if (_activeYouTubeConnectReturnMessages[widget.session] == result) {
          _activeYouTubeConnectReturnMessages[widget.session] = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _context.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => Stack(
        children: [
          SocialV2Scaffold(
            title: 'Share from YouTube',
            subtitle: 'Add a video or Short to your MoolSocial post',
            selectedTab: SocialV2Tab.create,
            onBack: () => Navigator.of(context).pop(),
            onTab: _onTab,
            body: switch (widget.session.youtubeStep) {
              YouTubeConnectStep.source => _source(),
              YouTubeConnectStep.action => _action(),
              YouTubeConnectStep.review => _review(),
              YouTubeConnectStep.complete => _complete(),
            },
          ),
          if (_returnMessage case final message?)
            Positioned(
              left: 16,
              right: 16,
              bottom: 96,
              child: SafeArea(
                top: false,
                child: Material(
                  key: const Key('youtube-connect-return-message'),
                  elevation: 8,
                  color: SocialV2Colors.navy,
                  borderRadius: BorderRadius.circular(14),
                  child: Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
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

  void _onTab(SocialV2Tab tab) {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    switch (tab) {
      case SocialV2Tab.mool:
        router.go('/app/mool');
      case SocialV2Tab.create:
        router.go('/app/social?sub=create');
      case SocialV2Tab.shorts:
        router.go('/app/social?sub=shorts');
      case SocialV2Tab.videos:
        router.go('/app/social?sub=videos');
      case SocialV2Tab.feed:
        router.go('/app/social?sub=feed');
      case SocialV2Tab.chat:
        router.go('/app/chat');
    }
  }

  List<Widget> _status() {
    final error = widget.session.errorMessage;
    final notice = widget.session.noticeMessage;
    if (error != null && error.isNotEmpty) {
      return [
        SocialV2Notice(title: 'Action needed', detail: error, warning: true),
      ];
    }
    if (notice != null && notice.isNotEmpty) {
      return [SocialV2Notice(title: 'Ready to continue', detail: notice)];
    }
    return const [];
  }

  Widget _progress(YouTubeConnectStep active) {
    final activeIndex = switch (active) {
      YouTubeConnectStep.source => 0,
      YouTubeConnectStep.action => 1,
      YouTubeConnectStep.review || YouTubeConnectStep.complete => 2,
    };
    const labels = ['Video', 'Details', 'Review'];
    return Row(
      children: List.generate(
        labels.length,
        (index) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: index <= activeIndex
                    ? SocialV2Colors.navy
                    : const Color(0xFFE4E5EE),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: index <= activeIndex
                        ? Colors.white
                        : SocialV2Colors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: const TextStyle(
                  color: SocialV2Colors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _source() {
    final session = widget.session;
    return SocialV2PageList(
      key: const ValueKey('youtube-connect-source'),
      children: [
        const SocialV2Hero(
          eyebrow: 'YouTube video or Short',
          title: 'Share a YouTube video on MoolSocial',
          detail:
              'Add a public link, write your post and review it before sharing.',
        ),
        _progress(YouTubeConnectStep.source),
        ..._status(),
        SocialV2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SocialV2SectionTitle(
                'Add a YouTube link',
                detail: 'Choose a public video or Short',
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('social-v2-youtube-url'),
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'YouTube video or Short link',
                  hintText: 'youtube.com/watch?v=…',
                ),
                onChanged: session.setYouTubeUrl,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('social-v2-youtube-validate'),
                onPressed: session.busy ? null : _validateLink,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(session.busy ? 'Opening…' : 'Continue'),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _explainChannelConnection,
          icon: const Icon(Icons.link_rounded),
          label: Text(
            session.youtubeChannelConnected
                ? 'YouTube channel connected'
                : 'Connect YouTube',
          ),
        ),
      ],
    );
  }

  Future<void> _validateLink() async {
    widget.session.setYouTubeUrl(_url.text);
    if (await widget.session.validateYouTubeSource() && mounted) {
      _continueToAction();
    }
  }

  Future<void> _explainChannelConnection() async {
    await showSocialV2Sheet(
      context,
      title: 'Connect YouTube',
      subtitle: 'Choose a Google account to find your channel videos',
      children: [
        const SocialV2ListTile(
          icon: Icons.person_search_outlined,
          title: 'Find your YouTube channel',
          detail: 'Choose a public video or Short to share',
        ),
        const SocialV2ListTile(
          icon: Icons.verified_user_outlined,
          title: 'Your videos stay on YouTube',
          detail: 'MoolSocial cannot edit or delete them',
        ),
        const SocialV2Notice(
          title: 'You remain in control',
          detail: 'You can disconnect YouTube from MoolSocial at any time.',
          warning: true,
        ),
        FilledButton(
          key: const Key('social-v2-youtube-connect-channel'),
          onPressed: () async {
            Navigator.of(context).pop();
            widget.session.setYouTubeChannelConnected(true);
            if (await widget.session.validateYouTubeSource() && mounted) {
              _continueToAction();
            }
          },
          child: const Text('Continue with Google'),
        ),
      ],
    );
  }

  void _continueToAction() {
    widget.session.continueToYouTubeAction();
  }

  Widget _action() {
    final session = widget.session;
    return SocialV2PageList(
      key: const ValueKey('youtube-connect-action'),
      children: [
        _progress(YouTubeConnectStep.action),
        ..._status(),
        const SocialV2SectionTitle(
          'Add post details',
          detail: 'Choose what people can do from your MoolSocial post',
        ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: creatorMoolActions.entries
              .map(
                (entry) => ChoiceChip(
                  key: Key('social-v2-youtube-action-${entry.key}'),
                  label: Text(entry.value),
                  selected: session.youtubeAction == entry.key,
                  onSelected: (_) => session.selectYouTubeAction(entry.key),
                ),
              )
              .toList(growable: false),
        ),
        DropdownButtonFormField<String>(
          initialValue: session.youtubeCategory,
          decoration: const InputDecoration(labelText: 'Category'),
          items: const [
            DropdownMenuItem(value: 'grocery', child: Text('Daily needs')),
            DropdownMenuItem(value: 'food', child: Text('Food')),
            DropdownMenuItem(value: 'service', child: Text('Local service')),
            DropdownMenuItem(value: 'work', child: Text('Work opportunity')),
          ],
          onChanged: (value) {
            if (value != null) session.setYouTubeCategory(value);
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: session.youtubeLocation,
          decoration: const InputDecoration(labelText: 'Available in'),
          items: const [
            DropdownMenuItem(value: 'jodhpur', child: Text('Jodhpur')),
            DropdownMenuItem(value: 'rajasthan', child: Text('Rajasthan')),
            DropdownMenuItem(value: 'india', child: Text('India')),
          ],
          onChanged: (value) {
            if (value != null) session.setYouTubeLocation(value);
          },
        ),
        TextFormField(
          initialValue: session.youtubeReference,
          decoration: const InputDecoration(
            labelText: 'Product, service or work',
          ),
          onChanged: session.setYouTubeReference,
        ),
        TextField(
          controller: _context,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'What the viewer can do next',
          ),
          onChanged: session.setYouTubeContext,
        ),
        SwitchListTile(
          value: session.youtubeSponsored,
          onChanged: session.setYouTubeSponsored,
          title: const Text('Paid partnership'),
          subtitle: const Text('Show a clear commercial disclosure'),
        ),
        SwitchListTile(
          value: session.youtubeCampaign != 'none',
          onChanged: (value) =>
              session.setYouTubeCampaign(value ? 'funded' : 'none'),
          title: const Text('Promote this MoolSocial post'),
          subtitle: const Text('Reach more people for a fixed duration'),
        ),
        if (session.youtubeCampaign != 'none')
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: creatorPlacementDays
                .map(
                  (days) => ChoiceChip(
                    label: Text('$days ${days == 1 ? 'day' : 'days'}'),
                    selected: session.youtubePlacementDays == days,
                    onSelected: (_) => session.setYouTubePlacementDays(days),
                  ),
                )
                .toList(growable: false),
          ),
        CheckboxListTile(
          value: session.youtubeRightsConfirmed,
          onChanged: (value) => session.confirmYouTubeRights(value ?? false),
          title: const Text('I have permission to share this video'),
          subtitle: const Text('The video remains on its YouTube channel'),
        ),
        CheckboxListTile(
          value: session.youtubeActionTruthConfirmed,
          onChanged: (value) =>
              session.confirmYouTubeActionTruth(value ?? false),
          title: const Text('The post information is accurate'),
          subtitle: const Text(
            'Price, availability, refund and destination are current',
          ),
        ),
        FilledButton(
          key: const Key('social-v2-youtube-action-next'),
          onPressed: _continueToCheck,
          child: const Text('Review post'),
        ),
        OutlinedButton(
          onPressed: session.backYouTubeStep,
          child: const Text('Change video'),
        ),
      ],
    );
  }

  void _continueToCheck() {
    widget.session.setYouTubeContext(_context.text);
    widget.session.continueToYouTubeReview();
  }

  Widget _review() {
    final session = widget.session;
    final action = creatorMoolActions[session.youtubeAction] ?? 'Continue';
    return SocialV2PageList(
      key: const ValueKey('youtube-connect-check'),
      children: [
        _progress(YouTubeConnectStep.review),
        ..._status(),
        const SocialV2Hero(
          eyebrow: 'Ready to share',
          title: 'Review your YouTube post',
          detail:
              'Check the video, post details and disclosure before publishing.',
        ),
        SocialV2ListTile(
          icon: Icons.ondemand_video_outlined,
          title: 'Selected YouTube video',
          detail: 'Public video or Short',
          badge: 'Video',
        ),
        SocialV2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'MOOLSOCIAL POST',
                style: TextStyle(
                  color: SocialV2Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$action · ${session.youtubeReference}',
                style: const TextStyle(
                  color: SocialV2Colors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(session.youtubeContext),
            ],
          ),
        ),
        if (session.youtubeCampaign != 'none')
          SocialV2Notice(
            title: '${session.youtubePlacementDays}-day promotion',
            detail:
                'Promotion begins after payment and approval. It does not renew automatically.',
            warning: true,
          ),
        FilledButton(
          key: const Key('social-v2-youtube-publish'),
          onPressed: session.busy ? null : _publish,
          child: Text(session.busy ? 'Publishing…' : 'Publish on MoolSocial'),
        ),
        OutlinedButton(
          onPressed: session.backYouTubeStep,
          child: const Text('Edit post details'),
        ),
      ],
    );
  }

  Future<void> _publish() async {
    await widget.session.publishYouTubeConnection();
  }

  Widget _complete() {
    final session = widget.session;
    return SocialV2PageList(
      key: const ValueKey('youtube-connect-complete'),
      children: [
        const SocialV2Hero(
          eyebrow: 'Published on MoolSocial',
          title: 'Your YouTube post is live',
          detail:
              'People can now watch the video and use the details you added.',
        ),
        ..._status(),
        SocialV2ListTile(
          icon: Icons.verified_rounded,
          title: 'YouTube video post',
          detail:
              '${creatorMoolActions[session.youtubeAction] ?? 'Action'} · ${session.youtubeReference}',
          badge: 'Published',
        ),
        if (session.youtubeCampaign != 'none')
          SocialV2Notice(
            title: 'Placement approval pending',
            detail:
                '${session.youtubePlacementDays * 24} purchased hours begin only after activation.',
            warning: true,
          ),
        FilledButton(
          onPressed: () => context.go('/app/social'),
          child: const Text('View post'),
        ),
        OutlinedButton(
          onPressed: session.restartYouTubeConnect,
          child: const Text('Share another YouTube video'),
        ),
      ],
    );
  }
}
