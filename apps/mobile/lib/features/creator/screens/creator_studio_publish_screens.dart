import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../creator_models.dart';
import '../creator_session.dart';
import '../widgets/creator_widgets.dart';

class CreatorStudioHomeScreen extends StatelessWidget {
  const CreatorStudioHomeScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Creator Studio',
        subtitle: '@JodhpurDaily · verified creator',
        activeDock: 'studio',
        returnRoute: '/app/creator',
        showBack: false,
        trailing: IconButton.outlined(
          key: const Key('creator-studio-controls'),
          tooltip: 'Open creator controls',
          onPressed: () => _controls(context),
          icon: const Icon(Icons.tune_rounded),
        ),
        body: ListView(
          key: const Key('creator-studio-home-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CreatorCard(
              color: MoolColors.navy,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VERIFIED VALUE THIS MONTH',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: MoolSpacing.xxs),
                        Text(
                          '₹48,620 influenced',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                          ),
                        ),
                        Text(
                          '₹8,940 payable · 3 active campaigns',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  CreatorPill(label: '86 TRUST', color: MoolColors.orange),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: CreatorMetric(
                    label: 'REACH',
                    value: '1.28L',
                    detail: 'attention',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'ENGAGED',
                    value: '18.4K',
                    detail: 'meaningful',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CreatorMetric(
                    label: 'CONVERTED',
                    value: '412',
                    detail: 'verified',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            const CreatorSectionTitle(
              title: 'Create & manage',
              detail: 'One tap to work',
            ),
            const SizedBox(height: MoolSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: MoolSpacing.xs,
              mainAxisSpacing: MoolSpacing.xs,
              childAspectRatio: 1.9,
              children: [
                _StudioAction(
                  keyName: 'creator-home-publish',
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Create',
                  detail: 'Reel, YouTube or post',
                  onTap: () => context.go('/app/creator/publish'),
                ),
                _StudioAction(
                  keyName: 'creator-home-library',
                  icon: Icons.video_library_outlined,
                  label: 'Library',
                  detail: 'Published, drafts and expiry',
                  onTap: () => context.go('/app/creator/content'),
                ),
                _StudioAction(
                  keyName: 'creator-home-campaigns',
                  icon: Icons.campaign_outlined,
                  label: 'Campaigns',
                  detail: 'Business-funded work',
                  onTap: () => context.go('/app/creator/campaigns'),
                ),
                _StudioAction(
                  keyName: 'creator-home-audience',
                  icon: Icons.groups_outlined,
                  label: 'Audience',
                  detail: 'Community and members',
                  onTap: () => context.go('/app/creator/audience'),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            const CreatorSectionTitle(
              title: 'Priority',
              detail: 'Continue the outcome',
            ),
            const SizedBox(height: MoolSpacing.sm),
            CreatorActionRow(
              keyName: 'creator-priority-campaign',
              icon: Icons.campaign_rounded,
              title: 'Campaign brief due today',
              detail: 'Local grocery explainer · business-funded Reel',
              meta: '₹3,500 reserved · disclosure required',
              action: 'Create',
              color: const Color(0xFFFFF6E8),
              onTap: () => context.go('/app/creator/publish?campaign=CR-2048'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            CreatorActionRow(
              keyName: 'creator-priority-ready',
              icon: Icons.play_circle_outline_rounded,
              title: 'Fresh basket Reel is ready',
              detail: 'Caption complete · 2-day funded run',
              meta: 'Ready for final review',
              action: 'Review',
              onTap: () => context.go('/app/creator/content?tab=drafts'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            CreatorActionRow(
              keyName: 'creator-priority-earnings',
              icon: Icons.account_balance_wallet_outlined,
              title: '₹6,240 available',
              detail: '2 campaign outcomes verified',
              meta: 'Automatic payout tomorrow',
              action: 'View',
              onTap: () => context.go('/app/creator/earnings'),
            ),
            const SizedBox(height: MoolSpacing.md),
            const CreatorSectionTitle(
              title: 'Recent performance',
              detail: 'Last 7 days',
            ),
            const SizedBox(height: MoolSpacing.sm),
            CreatorActionRow(
              keyName: 'creator-home-performance',
              icon: Icons.insights_outlined,
              title: 'How local baskets save time',
              detail: '48.2K views · 1,206 demand actions',
              meta: '126 paid orders · ₹2,840 payable',
              action: 'Inspect',
              onTap: () => context.go('/app/creator/performance'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _controls(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('creator-studio-controls-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Creator controls',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text('Channel, rights, team and account safety.'),
            const SizedBox(height: MoolSpacing.md),
            const CreatorCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  CreatorFact(label: 'Channel', value: 'Verified'),
                  CreatorFact(label: 'Earning access', value: 'Active'),
                  CreatorFact(label: 'Rights', value: '1 review'),
                  CreatorFact(label: 'Team', value: '2 members'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('creator-controls-open'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/app/creator/control');
                },
                child: const Text('Manage Channel & Safety'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('creator-controls-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CreatorPublishScreen extends StatelessWidget {
  const CreatorPublishScreen({required this.session, super.key});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CreatorPageScaffold(
        session: session,
        title: 'Create & Publish',
        subtitle: 'Business-funded Reels, YouTube and posts',
        activeDock: 'create',
        returnRoute: '/app/creator',
        trailing: IconButton.outlined(
          key: const Key('creator-open-drafts'),
          tooltip: 'Open drafts',
          onPressed: () => context.go('/app/creator/content?tab=drafts'),
          icon: const Icon(Icons.drafts_outlined),
        ),
        bottomAction: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('creator-save-draft'),
                onPressed: session.busy ? null : session.saveDraft,
                child: Text(session.draftId == null ? 'Save Draft' : 'Saved'),
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: FilledButton(
                key: const Key('creator-review-publish'),
                onPressed: session.publishFormat == CreatorPublishFormat.youtube
                    ? () => context.go('/app/creator/youtube-connect')
                    : () => _review(context),
                child: Text(
                  session.publishFormat == CreatorPublishFormat.youtube
                      ? 'Start YouTube Connect'
                      : 'Review & Publish',
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          key: const Key('creator-publish-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CreatorSectionTitle(
              title: 'Choose format',
              detail: 'Cost-aware publishing',
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CreatorPublishFormat.values
                    .map(
                      (format) => Padding(
                        padding: const EdgeInsets.only(right: MoolSpacing.xs),
                        child: MoolSegment(
                          key: Key('creator-format-${format.name}'),
                          label: switch (format) {
                            CreatorPublishFormat.reel => 'Funded Reel',
                            CreatorPublishFormat.youtube => 'YouTube',
                            CreatorPublishFormat.text => 'Text Post',
                            CreatorPublishFormat.image => 'Image Post',
                          },
                          selected: session.publishFormat == format,
                          onPressed: () => session.selectPublishFormat(format),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            if (session.publishFormat == CreatorPublishFormat.youtube)
              _YouTubeChoiceCard(session: session)
            else ...[
              if (session.publishFormat != CreatorPublishFormat.text)
                _MediaPicker(session: session),
              if (session.publishFormat == CreatorPublishFormat.reel) ...[
                const SizedBox(height: MoolSpacing.sm),
                _FundedReelTerms(session: session),
              ],
              const SizedBox(height: MoolSpacing.sm),
              TextFormField(
                key: const Key('creator-post-title'),
                initialValue: session.postTitle,
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: session.setPostTitle,
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextFormField(
                key: const Key('creator-post-caption'),
                initialValue: session.postCaption,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Caption and context',
                  hintText: 'Tell people what they will see or accomplish.',
                ),
                onChanged: session.setPostCaption,
              ),
              const SizedBox(height: MoolSpacing.sm),
              CreatorCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      key: const Key('creator-sponsored'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Paid partnership disclosure'),
                      subtitle: const Text(
                        'Turn on when a business funds or incentivizes this content.',
                      ),
                      value:
                          session.publishFormat == CreatorPublishFormat.reel ||
                          session.sponsored,
                      onChanged:
                          session.publishFormat == CreatorPublishFormat.reel
                          ? null
                          : session.setSponsored,
                    ),
                    CheckboxListTile(
                      key: const Key('creator-rights-confirm'),
                      contentPadding: EdgeInsets.zero,
                      value: session.rightsConfirmed,
                      onChanged: (value) =>
                          session.confirmRights(value ?? false),
                      title: const Text(
                        'I control the media rights and permissions',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _review(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('creator-publish-review-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Final publishing review',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'Confirm what viewers see and what the business funds.',
                ),
                const SizedBox(height: MoolSpacing.md),
                CreatorCard(
                  color: const Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      CreatorFact(
                        label: 'Format',
                        value: switch (session.publishFormat) {
                          CreatorPublishFormat.reel => 'Business-funded Reel',
                          CreatorPublishFormat.text => 'Text post',
                          CreatorPublishFormat.image => 'Image post',
                          CreatorPublishFormat.youtube => 'YouTube',
                        },
                      ),
                      if (session.publishFormat ==
                          CreatorPublishFormat.reel) ...[
                        CreatorFact(
                          label: 'Business',
                          value: session.reelFundingCampaign.sponsor,
                        ),
                        CreatorFact(
                          label: 'Funded pay',
                          value: '₹${session.reelFundingCampaign.fixedPay}',
                        ),
                        CreatorFact(
                          label: 'Live for',
                          value:
                              '${session.reelDurationDays} day${session.reelDurationDays == 1 ? '' : 's'}',
                        ),
                        const CreatorFact(
                          label: 'After duration',
                          value: 'Unpublishes automatically',
                        ),
                      ],
                      CreatorFact(
                        label: 'Disclosure',
                        value:
                            session.publishFormat ==
                                    CreatorPublishFormat.reel ||
                                session.sponsored
                            ? 'Paid partnership'
                            : 'Not sponsored',
                      ),
                      CreatorFact(
                        label: 'Audience',
                        value: session.visibility == 'public'
                            ? 'Public'
                            : 'Followers',
                      ),
                    ],
                  ),
                ),
                if (session.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: MoolSpacing.sm),
                    child: Text(
                      session.errorMessage!,
                      key: const Key('creator-publish-error'),
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('creator-publish-confirm'),
                    onPressed: session.busy ? null : session.publishNativePost,
                    child: Text(
                      session.publishedPostId == null
                          ? 'Publish Now'
                          : 'Published',
                    ),
                  ),
                ),
                if (session.publishedPostId != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const Key('creator-publish-view-library'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.go('/app/creator/content');
                      },
                      child: const Text('View in Content Library'),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('creator-publish-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
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

class _StudioAction extends StatelessWidget {
  const _StudioAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CreatorCard(
    keyName: keyName,
    onTap: onTap,
    padding: const EdgeInsets.symmetric(
      horizontal: MoolSpacing.xs,
      vertical: MoolSpacing.sm,
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: MoolColors.navy.withValues(alpha: .08),
          foregroundColor: MoolColors.navy,
          child: Icon(icon, size: 21),
        ),
        const SizedBox(width: MoolSpacing.xs),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: MoolColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MediaPicker extends StatelessWidget {
  const _MediaPicker({required this.session});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) => CreatorCard(
    keyName: 'creator-media-picker',
    color: session.mediaSelected
        ? const Color(0xFFEAF7E8)
        : const Color(0xFFF4F3FF),
    child: Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: MoolColors.navy.withValues(alpha: .08),
          child: Icon(
            session.mediaSelected
                ? Icons.check_rounded
                : Icons.add_photo_alternate_outlined,
            color: MoolColors.navy,
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        Text(
          session.mediaSelected
              ? 'Media selected'
              : session.publishFormat == CreatorPublishFormat.reel
              ? 'Add a Reel up to 60 seconds'
              : 'Add one image',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        Text(
          session.publishFormat == CreatorPublishFormat.reel
              ? 'Camera, Gallery or Files · auto-unpublishes after its funded run'
              : 'Camera, Gallery or Files',
          textAlign: TextAlign.center,
          style: const TextStyle(color: MoolColors.muted, fontSize: 11),
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            for (final source in const ['camera', 'gallery', 'files'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: OutlinedButton(
                    key: Key('creator-media-$source'),
                    onPressed: () => session.selectMedia(),
                    child: Text(
                      '${source[0].toUpperCase()}${source.substring(1)}',
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (session.mediaSelected)
          TextButton(
            key: const Key('creator-media-remove'),
            onPressed: session.clearMedia,
            child: const Text('Remove Media'),
          ),
      ],
    ),
  );
}

class _FundedReelTerms extends StatelessWidget {
  const _FundedReelTerms({required this.session});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) => CreatorCard(
    keyName: 'creator-reel-funding',
    color: const Color(0xFFFFF6E8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Business-funded Reel',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            CreatorPill(
              label: '₹${session.reelFundingCampaign.fixedPay} RESERVED',
              color: MoolColors.success,
            ),
          ],
        ),
        Text(
          session.reelFundingCampaign.title,
          style: const TextStyle(color: MoolColors.muted, fontSize: 11),
        ),
        const SizedBox(height: MoolSpacing.sm),
        const Text(
          'Choose paid run',
          style: TextStyle(fontWeight: FontWeight.w900),
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
                      key: Key('creator-reel-days-$days'),
                      label: '$days day${days == 1 ? '' : 's'}',
                      selected: session.reelDurationDays == days,
                      onPressed: () => session.setReelDuration(days),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        Text(
          'The business funds this run. The Reel unpublishes automatically after ${session.reelDurationDays} day${session.reelDurationDays == 1 ? '' : 's'}.',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        CheckboxListTile(
          key: const Key('creator-reel-funding-terms'),
          contentPadding: EdgeInsets.zero,
          value: session.reelFundingReviewed,
          onChanged: (value) => session.acceptReelFunding(value ?? false),
          title: const Text(
            'I reviewed the sponsor, pay, duration, disclosure and expiry',
          ),
        ),
      ],
    ),
  );
}

class _YouTubeChoiceCard extends StatelessWidget {
  const _YouTubeChoiceCard({required this.session});

  final CreatorSession session;

  @override
  Widget build(BuildContext context) => CreatorCard(
    keyName: 'creator-youtube-choice',
    color: const Color(0xFFF4F3FF),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFFFEDEC),
              foregroundColor: Color(0xFFC62828),
              child: Icon(Icons.play_arrow_rounded),
            ),
            SizedBox(width: MoolSpacing.sm),
            Expanded(
              child: Text(
                'Connect a YouTube video or Short',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        const Text(
          'The video remains on YouTube. MoolSocial publishes its context and one separate Buy, Book, Order, Apply, Visit or Chat action.',
        ),
        const SizedBox(height: MoolSpacing.sm),
        const CreatorFact(label: 'Video hosting', value: 'YouTube'),
        const CreatorFact(
          label: 'MoolSocial stores',
          value: 'Connection, disclosure and action',
        ),
        const CreatorFact(
          label: 'Channel access',
          value: 'Read-only and revocable',
        ),
        const SizedBox(height: MoolSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('creator-youtube-start'),
            onPressed: () => context.go('/app/creator/youtube-connect'),
            icon: const Icon(Icons.link_rounded),
            label: const Text('Start YouTube Connect'),
          ),
        ),
      ],
    ),
  );
}
