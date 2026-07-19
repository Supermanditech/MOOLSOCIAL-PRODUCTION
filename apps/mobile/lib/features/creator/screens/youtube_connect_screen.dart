import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../creator_models.dart';
import '../creator_session.dart';
import '../widgets/creator_widgets.dart';

class CreatorYouTubeConnectScreen extends StatelessWidget {
  const CreatorYouTubeConnectScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'YouTube Connect',
        subtitle: 'Video on YouTube · one separate Mool action',
        activeDock: 'create',
        returnRoute: '/app/creator/publish',
        trailing: IconButton.outlined(
          key: const Key('youtube-connect-help'),
          tooltip: 'How YouTube Connect works',
          onPressed: () => _help(context),
          icon: const Icon(Icons.help_outline_rounded),
        ),
        bottomAction: _bottomAction(context),
        body: ListView(
          key: const Key('youtube-connect-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            _ConnectProgress(step: session.youtubeStep),
            const SizedBox(height: MoolSpacing.md),
            switch (session.youtubeStep) {
              YouTubeConnectStep.source => _SourceStep(
                session: session,
                onConnect: () => _connectChannel(context),
              ),
              YouTubeConnectStep.action => _ActionStep(session: session),
              YouTubeConnectStep.review => _ReviewStep(session: session),
              YouTubeConnectStep.complete => _CompleteStep(session: session),
            },
          ],
        ),
      ),
    );
  }

  Widget _bottomAction(BuildContext context) {
    return switch (session.youtubeStep) {
      YouTubeConnectStep.source => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('youtube-source-cancel'),
              onPressed: () => context.go('/app/creator/publish'),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: FilledButton(
              key: const Key('youtube-source-continue'),
              onPressed: session.continueToYouTubeAction,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
      YouTubeConnectStep.action => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('youtube-action-back'),
              onPressed: session.backYouTubeStep,
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: FilledButton(
              key: const Key('youtube-action-preview'),
              onPressed: session.continueToYouTubeReview,
              child: const Text('Preview Post'),
            ),
          ),
        ],
      ),
      YouTubeConnectStep.review => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('youtube-review-back'),
              onPressed: session.backYouTubeStep,
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: FilledButton(
              key: const Key('youtube-publish'),
              onPressed: session.busy ? null : session.publishYouTubeConnection,
              child: const Text('Publish Connected Post'),
            ),
          ),
        ],
      ),
      YouTubeConnectStep.complete => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('youtube-create-another'),
              onPressed: session.restartYouTubeConnect,
              child: const Text('Create Another'),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: FilledButton(
              key: const Key('youtube-view-connected'),
              onPressed: () => context.go('/app/creator/content'),
              child: const Text('View Connected Post'),
            ),
          ),
        ],
      ),
    };
  }

  Future<void> _connectChannel(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            key: const Key('youtube-channel-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect your YouTube channel',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const Text('Google authorization opens only after you continue.'),
              const SizedBox(height: MoolSpacing.md),
              const CreatorCard(
                color: Color(0xFFF4F3FF),
                child: Column(
                  children: [
                    CreatorFact(label: 'Access', value: 'Read public content'),
                    CreatorFact(
                      label: 'Upload permission',
                      value: 'Not requested',
                    ),
                    CreatorFact(label: 'Password', value: 'Never shared'),
                    CreatorFact(label: 'Connection', value: 'Revoke anytime'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('youtube-channel-confirm'),
                  onPressed: () {
                    session.setYouTubeChannelConnected(true);
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Continue to Google'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('youtube-channel-cancel'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _help(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            key: const Key('youtube-help-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How the connection works',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const CreatorFact(
                label: 'Video and views',
                value: 'Remain on YouTube',
              ),
              const CreatorFact(
                label: 'MoolSocial',
                value: 'Adds context and one action',
              ),
              const CreatorFact(
                label: 'YouTube engagement',
                value: 'Never paid by MoolSocial',
              ),
              const CreatorFact(
                label: 'Campaign outcome',
                value: 'Measured outside the player',
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('youtube-help-close'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ConnectProgress extends StatelessWidget {
  const _ConnectProgress({required this.step});

  final YouTubeConnectStep step;

  @override
  Widget build(BuildContext context) {
    final active = switch (step) {
      YouTubeConnectStep.source => 0,
      YouTubeConnectStep.action => 1,
      YouTubeConnectStep.review || YouTubeConnectStep.complete => 2,
    };
    return Row(
      children: [
        for (var index = 0; index < 3; index += 1) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                color: index <= active
                    ? MoolColors.navy
                    : const Color(0xFFD9DCE8),
              ),
            ),
          _ProgressNode(
            number: index + 1,
            label: const ['Source', 'Action', 'Review'][index],
            selected: index == active,
            complete: index < active,
          ),
        ],
      ],
    );
  }
}

class _ProgressNode extends StatelessWidget {
  const _ProgressNode({
    required this.number,
    required this.label,
    required this.selected,
    required this.complete,
  });

  final int number;
  final String label;
  final bool selected;
  final bool complete;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: selected || complete
            ? MoolColors.navy
            : const Color(0xFFECEEF5),
        foregroundColor: selected || complete ? Colors.white : MoolColors.muted,
        child: complete
            ? const Icon(Icons.check_rounded, size: 17)
            : Text(
                '$number',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        style: TextStyle(
          color: selected ? MoolColors.navy : MoolColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _SourceStep extends StatelessWidget {
  const _SourceStep({required this.session, required this.onConnect});

  final CreatorSession session;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('youtube-source-step'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CreatorSectionTitle(
        title: 'Choose YouTube content',
        detail: 'Public and embeddable',
      ),
      const SizedBox(height: MoolSpacing.sm),
      CreatorCard(
        color: const Color(0xFFF4F3FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CreatorPill(label: 'FASTEST', color: MoolColors.navy),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Paste one YouTube link',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Validate a public video or Short without connecting the complete channel.',
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextFormField(
              key: const Key('youtube-url'),
              initialValue: session.youtubeUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'YouTube link',
                hintText: 'https://youtube.com/watch?v=…',
              ),
              onChanged: session.setYouTubeUrl,
            ),
            const SizedBox(height: MoolSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('youtube-validate'),
                onPressed: session.busy ? null : session.validateYouTubeSource,
                child: Text(
                  session.youtubeValidated
                      ? 'Video Validated'
                      : 'Validate Link',
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: MoolSpacing.sm),
      CreatorCard(
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFEDEC),
              foregroundColor: Color(0xFFC62828),
              child: Icon(Icons.play_arrow_rounded),
            ),
            const SizedBox(width: MoolSpacing.sm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect my channel',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Choose from eligible public channel content.',
                    style: TextStyle(color: MoolColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const Key('youtube-connect-channel'),
              onPressed: onConnect,
              child: Text(
                session.youtubeChannelConnected ? 'Connected' : 'Connect',
              ),
            ),
          ],
        ),
      ),
      if (session.youtubeChannelConnected) ...[
        const SizedBox(height: MoolSpacing.sm),
        CreatorActionRow(
          keyName: 'youtube-channel-video',
          icon: Icons.video_library_outlined,
          title: 'How local baskets save time',
          detail: 'YouTube Short · public · embedding allowed',
          meta: '@JodhpurDaily · read-only access',
          action: session.youtubeValidated ? 'Selected' : 'Select',
          onTap: session.validateYouTubeSource,
        ),
      ],
    ],
  );
}

class _ActionStep extends StatelessWidget {
  const _ActionStep({required this.session});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('youtube-action-step'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CreatorSectionTitle(
        title: 'What should people accomplish?',
        detail: 'Choose exactly one',
      ),
      const SizedBox(height: MoolSpacing.sm),
      Wrap(
        spacing: MoolSpacing.xs,
        runSpacing: MoolSpacing.xs,
        children: creatorMoolActions.entries
            .map(
              (entry) => ChoiceChip(
                key: Key('youtube-action-${entry.key}'),
                label: Text(entry.value),
                selected: session.youtubeAction == entry.key,
                onSelected: (_) => session.selectYouTubeAction(entry.key),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: MoolSpacing.md),
      DropdownButtonFormField<String>(
        key: const Key('youtube-category'),
        isExpanded: true,
        initialValue: session.youtubeCategory,
        decoration: const InputDecoration(labelText: 'Category'),
        items: const [
          DropdownMenuItem(value: 'grocery', child: Text('Daily needs')),
          DropdownMenuItem(value: 'food', child: Text('Restaurant and food')),
          DropdownMenuItem(value: 'service', child: Text('Local service')),
          DropdownMenuItem(value: 'work', child: Text('Funded work')),
        ],
        onChanged: (value) => session.setYouTubeCategory(value ?? 'grocery'),
      ),
      const SizedBox(height: MoolSpacing.sm),
      DropdownButtonFormField<String>(
        key: const Key('youtube-location'),
        isExpanded: true,
        initialValue: session.youtubeLocation,
        decoration: const InputDecoration(labelText: 'Location'),
        items: const [
          DropdownMenuItem(value: 'jodhpur', child: Text('Jodhpur pilot area')),
          DropdownMenuItem(
            value: 'rajasthan',
            child: Text('Rajasthan enabled areas'),
          ),
          DropdownMenuItem(value: 'india', child: Text('India enabled areas')),
        ],
        onChanged: (value) => session.setYouTubeLocation(value ?? 'jodhpur'),
      ),
      const SizedBox(height: MoolSpacing.sm),
      TextFormField(
        key: const Key('youtube-reference'),
        initialValue: session.youtubeReference,
        decoration: const InputDecoration(
          labelText: 'Product, service or work',
        ),
        onChanged: session.setYouTubeReference,
      ),
      const SizedBox(height: MoolSpacing.sm),
      TextFormField(
        key: const Key('youtube-context'),
        initialValue: session.youtubeContext,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Exact user-facing outcome',
        ),
        onChanged: session.setYouTubeContext,
      ),
      const SizedBox(height: MoolSpacing.sm),
      CreatorCard(
        child: Column(
          children: [
            SwitchListTile(
              key: const Key('youtube-sponsored'),
              contentPadding: EdgeInsets.zero,
              value: session.youtubeSponsored,
              onChanged: session.setYouTubeSponsored,
              title: const Text('Paid partnership'),
              subtitle: const Text('Show commercial disclosure on the post.'),
            ),
            DropdownButtonFormField<String>(
              key: const Key('youtube-campaign'),
              isExpanded: true,
              initialValue: session.youtubeCampaign,
              decoration: const InputDecoration(
                labelText: 'Campaign association',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'none',
                  child: Text('No funded placement'),
                ),
                DropdownMenuItem(
                  value: 'CR-2048',
                  child: Text('Funded Campaign Reel · CR-2048'),
                ),
              ],
              onChanged: (value) => session.setYouTubeCampaign(value ?? 'none'),
            ),
            if (session.youtubeCampaign != 'none') ...[
              const SizedBox(height: MoolSpacing.sm),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Funded discovery duration',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: creatorPlacementDays
                      .map(
                        (days) => Padding(
                          padding: const EdgeInsets.only(right: MoolSpacing.xs),
                          child: MoolSegment(
                            key: Key('youtube-days-$days'),
                            label: '$days day${days == 1 ? '' : 's'}',
                            selected: session.youtubePlacementDays == days,
                            onPressed: () =>
                                session.setYouTubePlacementDays(days),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: MoolSpacing.xs),
                child: Text(
                  'The paid discovery placement ends after this duration. The YouTube video itself stays on YouTube.',
                  style: TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ),
            ],
            CheckboxListTile(
              key: const Key('youtube-rights'),
              contentPadding: EdgeInsets.zero,
              value: session.youtubeRightsConfirmed,
              onChanged: (value) =>
                  session.confirmYouTubeRights(value ?? false),
              title: const Text('I control the required video rights'),
            ),
            CheckboxListTile(
              key: const Key('youtube-action-truth'),
              contentPadding: EdgeInsets.zero,
              value: session.youtubeActionTruthConfirmed,
              onChanged: (value) =>
                  session.confirmYouTubeActionTruth(value ?? false),
              title: const Text(
                'The attached action, price, availability and outcome are accurate',
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.session});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('youtube-review-step'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CreatorSectionTitle(
        title: 'Review connected post',
        detail: 'YouTube and Mool stay separate',
      ),
      const SizedBox(height: MoolSpacing.sm),
      CreatorCard(
        color: const Color(0xFF11111A),
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF262633),
                borderRadius: BorderRadius.circular(MoolRadii.control),
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFFC62828),
                  child: Icon(Icons.play_arrow_rounded, size: 38),
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'How local baskets save time',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Video plays from YouTube',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: MoolSpacing.sm),
      CreatorCard(
        keyName: 'youtube-mool-action-preview',
        color: const Color(0xFFF4F3FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CreatorPill(
              label: 'MOOLSOCIAL ACTION · OUTSIDE PLAYER',
              color: MoolColors.navy,
            ),
            const SizedBox(height: MoolSpacing.sm),
            Text(
              creatorMoolActions[session.youtubeAction] ?? 'Action',
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              session.youtubeReference,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(session.youtubeContext),
            const SizedBox(height: MoolSpacing.sm),
            CreatorFact(
              label: 'Disclosure',
              value: session.youtubeSponsored
                  ? 'Paid partnership'
                  : 'Not sponsored',
            ),
            CreatorFact(
              label: 'Campaign',
              value: session.youtubeCampaign == 'none'
                  ? 'No funded placement'
                  : '${session.youtubePlacementDays}-day funded placement',
            ),
          ],
        ),
      ),
      const SizedBox(height: MoolSpacing.sm),
      const CreatorCard(
        color: Color(0xFFFFF6E8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFB05C00)),
            SizedBox(width: MoolSpacing.sm),
            Expanded(
              child: Text(
                'The player never disguises a paid MoolSocial outcome as a YouTube engagement reward.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({required this.session});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('youtube-complete-step'),
    children: [
      const SizedBox(height: MoolSpacing.lg),
      const CircleAvatar(
        radius: 38,
        backgroundColor: Color(0xFFEAF7E8),
        foregroundColor: MoolColors.success,
        child: Icon(Icons.check_rounded, size: 40),
      ),
      const SizedBox(height: MoolSpacing.md),
      const Text(
        'Connected post created',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: MoolSpacing.xs),
      const Text(
        'Your video remains on YouTube. MoolSocial published only its validated connection, context, disclosure and separate action.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: MoolSpacing.md),
      CreatorCard(
        color: const Color(0xFFF4F3FF),
        child: Column(
          children: [
            CreatorFact(
              label: 'Connected post',
              value: session.youtubeConnectedPostId ?? 'Ready',
            ),
            const CreatorFact(label: 'Video host', value: 'YouTube'),
            CreatorFact(
              label: 'Mool action',
              value: creatorMoolActions[session.youtubeAction] ?? 'Selected',
            ),
            CreatorFact(
              label: 'Paid placement',
              value: session.youtubeCampaign == 'none'
                  ? 'None'
                  : '${session.youtubePlacementDays} days',
            ),
          ],
        ),
      ),
    ],
  );
}
