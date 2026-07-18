import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../journey_session.dart';
import '../universal_intent_catalog.dart';
import '../widgets/intent_completion_sheet.dart';
import '../widgets/journey_frame.dart';

class UniversalShell extends StatefulWidget {
  const UniversalShell({
    required this.session,
    required this.section,
    this.initialSubAction,
    super.key,
  });

  final JourneySession session;
  final String section;
  final String? initialSubAction;

  @override
  State<UniversalShell> createState() => _UniversalShellState();
}

class _UniversalShellState extends State<UniversalShell> {
  static const _knownSections = {
    'social',
    'buy',
    'eat',
    'ride',
    'book',
    'pay',
    'work',
    'chat',
    'mool',
  };

  String _socialTab = 'Shorts';
  final Map<String, String> _focusedSubActions =
      UniversalIntentCatalog.initialSelection();

  @override
  void initState() {
    super.initState();
    _applyInitialSubAction();
  }

  @override
  void didUpdateWidget(covariant UniversalShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section ||
        oldWidget.initialSubAction != widget.initialSubAction) {
      _applyInitialSubAction();
    }
  }

  void _applyInitialSubAction() {
    final requested = widget.initialSubAction;
    if (requested == null) return;
    final valid = UniversalIntentCatalog.forSection(
      widget.section,
    ).any((spec) => spec.id == requested);
    if (valid) _focusedSubActions[widget.section] = requested;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.session.confirmReadyRoute('/app/${widget.section}');
    });

    final requestedSection = _knownSections.contains(widget.section)
        ? widget.section
        : 'social';
    final moolOpen = requestedSection == 'mool';
    final activeSection = moolOpen
        ? widget.session.previousPrimarySection
        : requestedSection;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MoolColors.navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MoolColors.navy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MoolColors.navy,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: const Color(0xFFF6F8FB),
                        child: Column(
                          children: [
                            _UniversalHeader(
                              session: widget.session,
                              section: activeSection,
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: MoolMotion.accessible(
                                  context,
                                  MoolMotion.standard,
                                ),
                                child: activeSection == 'social'
                                    ? _SocialSurface(
                                        key: const ValueKey('social'),
                                        selectedTab: _socialTab,
                                        onTabChanged: (tab) {
                                          setState(() => _socialTab = tab);
                                        },
                                      )
                                    : _WorldSurface(
                                        key: ValueKey(activeSection),
                                        section: activeSection,
                                        selectedSubAction:
                                            _focusedSubActions[activeSection],
                                        returnSection: widget
                                            .session
                                            .previousPrimarySection,
                                        onSubActionChanged: (id) {
                                          setState(
                                            () =>
                                                _focusedSubActions[activeSection] =
                                                    id,
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (activeSection == 'social')
                      Positioned(
                        top: 178,
                        right: 12,
                        child: _ContentActionRail(tab: _socialTab),
                      ),
                    if (moolOpen)
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 92,
                        child: _MoolCommandPalette(
                          activeSection: activeSection,
                        ),
                      ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: _UniversalDock(
                        session: widget.session,
                        activeSection: activeSection,
                        moolOpen: moolOpen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UniversalHeader extends StatelessWidget {
  const _UniversalHeader({required this.session, required this.section});

  final JourneySession session;
  final String section;

  @override
  Widget build(BuildContext context) {
    final command = switch (section) {
      'buy' => 'Search grocery, categories, medicine or household basket',
      'eat' => 'Search restaurants, tiffin, cafes or tables',
      'ride' => 'Search bike, auto or cab',
      'book' => 'Search get it done, doctor or salon',
      'pay' => 'Search recharge, bills, scan pay or receipts',
      'work' => 'Search earn today, delivery, onboarding or verification',
      'chat' => 'Search people, business, orders or support',
      _ => 'Search YouTube videos, people or native posts',
    };
    return Container(
      color: MoolColors.navy,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoolSocial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: .95,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    PrototypeIdentityLine(width: 118, height: 3),
                  ],
                ),
              ),
              Semantics(
                key: const Key('open-profile'),
                button: true,
                label: 'Open your account',
                child: InkWell(
                  onTap: () => _showProfile(context, session),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: MoolMetrics.minimumTapTarget,
                    height: MoolMetrics.minimumTapTarget,
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white),
                        ),
                        child: const ExcludeSemantics(
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: MoolColors.navy,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            constraints: const BoxConstraints(
              minHeight: MoolMetrics.minimumTapTarget,
            ),
            padding: const EdgeInsets.fromLTRB(11, 4, 5, 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    command,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _HeaderAction(
                  key: const Key('open-search'),
                  label: 'Search MoolSocial',
                  icon: Icons.search_rounded,
                  onTap: () => _showSearch(context),
                ),
                const SizedBox(width: 5),
                _HeaderAction(
                  key: const Key('open-scan'),
                  label: 'Scan or enter a code',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () =>
                      _showQuickInputSheet(context, type: _QuickInputType.scan),
                ),
                const SizedBox(width: 5),
                _HeaderAction(
                  key: const Key('open-voice'),
                  label: 'Voice or typed search',
                  icon: Icons.mic_none_rounded,
                  onTap: () => _showQuickInputSheet(
                    context,
                    type: _QuickInputType.voice,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: MoolMetrics.minimumTapTarget,
          height: MoolMetrics.minimumTapTarget,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: MoolColors.navy, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialSurface extends StatelessWidget {
  const _SocialSurface({
    required this.selectedTab,
    required this.onTabChanged,
    super.key,
  });

  final String selectedTab;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('section-social'),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 104),
      children: [
        const _YouTubeConnectCard(),
        const SizedBox(height: 8),
        _SocialTabStrip(selectedTab: selectedTab, onChanged: onTabChanged),
        const SizedBox(height: 10),
        if (selectedTab == 'Shorts') ...[
          const _VideoCard(
            badge: 'YouTube',
            secondBadge: 'Swipe',
            title: 'Short videos start instantly',
            copy:
                'Local shorts, reels, creators, offers and daily moments. '
                'Swipe vertically to watch the next short.',
          ),
          const SizedBox(height: 10),
          const _DecisionCard(
            icon: Icons.edit_outlined,
            title: 'Create short',
            copy:
                'Record, upload, trim, caption and post. Creator monetisation '
                'unlocks only after verification.',
            actions: ['Record', 'Caption', 'Post'],
          ),
        ] else if (selectedTab == 'Videos') ...[
          const _VideoCard(
            badge: 'YouTube',
            secondBadge: '12:48',
            title: 'Watch long videos without distraction',
            copy:
                'Creator channels, education, product explainers, local '
                'stories and live commerce videos play in one dedicated view.',
          ),
          const SizedBox(height: 10),
          const _DecisionCard(
            icon: Icons.ondemand_video_outlined,
            title: 'Continue watching',
            copy:
                'Resume, subscribe, save, share or open creator channel. '
                'Open Buy only when a video includes a verified product.',
            actions: ['Resume', 'Channel', 'Save'],
          ),
        ] else if (selectedTab == 'Feed') ...[
          const _DecisionCard(
            icon: Icons.view_agenda_outlined,
            title: 'Local feed post',
            copy:
                'People, shops, creators and communities can post updates, '
                'photos, opinions, offers and local alerts.',
            actions: ['Like', 'Comment', 'Share'],
          ),
          const SizedBox(height: 10),
          const _DecisionCard(
            icon: Icons.edit_outlined,
            title: 'Create post',
            copy:
                'Write, upload image, tag area, mention people or attach a '
                'service experience.',
            actions: ['Text', 'Photo', 'Area'],
          ),
        ] else
          const _DecisionCard(
            icon: Icons.edit_outlined,
            title: 'Create social post',
            copy:
                'Start with text, photo, short video, long video or local '
                'business proof. Creator tools unlock after verification.',
            actions: ['Text', 'Photo', 'Video', 'Proof'],
          ),
      ],
    );
  }
}

class _YouTubeConnectCard extends StatelessWidget {
  const _YouTubeConnectCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF2F3FF)],
        ),
        border: Border.all(color: const Color(0xFFC9CDEC)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000080),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: MoolColors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'YOUTUBE CONNECT',
                  style: TextStyle(
                    color: MoolColors.success,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'YouTube video. MoolSocial action.',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Discover connected YouTube videos and time-bound Campaign '
                  'Reels. Text and photo posts stay native.',
                  style: TextStyle(
                    color: Color(0xFF68708A),
                    fontSize: 9,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 9),
                const Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _LaunchTag('YouTube hosted'),
                    _LaunchTag('Mool actions'),
                    _LaunchTag('No paid views'),
                  ],
                ),
                const SizedBox(height: 9),
                FilledButton(
                  key: const Key('social-open-video'),
                  onPressed: () => _showSocialDetailSheet(
                    context,
                    title: 'YouTube video with a Mool action',
                    description:
                        'The video remains hosted by YouTube. Choose the '
                        'MoolSocial action below the player when you want to '
                        'buy, book, order, apply, visit or chat.',
                    primaryLabel: 'Open connected video',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      MoolMetrics.minimumTapTarget,
                    ),
                    backgroundColor: MoolColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('Open connected video'),
                ),
                const SizedBox(height: 7),
                OutlinedButton(
                  key: const Key('social-how-it-works'),
                  onPressed: () => _showSocialDetailSheet(
                    context,
                    title: 'How connected video works',
                    description:
                        'Video stays on YouTube. MoolSocial validates the '
                        'public connection and adds a separate Buy, Book, '
                        'Order, Apply, Visit or Chat action.',
                    primaryLabel: 'Got it',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      MoolMetrics.minimumTapTarget,
                    ),
                    foregroundColor: MoolColors.navy,
                    side: const BorderSide(color: MoolColors.navy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('How it works'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchTag extends StatelessWidget {
  const _LaunchTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBFF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: MoolColors.navy,
          fontSize: 7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SocialTabStrip extends StatelessWidget {
  const _SocialTabStrip({required this.selectedTab, required this.onChanged});

  final String selectedTab;
  final ValueChanged<String> onChanged;

  static const tabs = ['Shorts', 'Videos', 'Feed', 'Create'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tabs.map((tab) {
        final selected = tab == selectedTab;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: tab == tabs.last ? 0 : 6),
            child: InkWell(
              key: Key('social-tab-${tab.toLowerCase()}'),
              onTap: () => onChanged(tab),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: MoolMetrics.minimumTapTarget,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? MoolColors.navy : Colors.white,
                  border: Border.all(
                    color: selected ? MoolColors.navy : const Color(0x2E000080),
                  ),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000080),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: selected ? Colors.white : MoolColors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.badge,
    required this.secondBadge,
    required this.title,
    required this.copy,
  });

  final String badge;
  final String secondBadge;
  final String title;
  final String copy;

  @override
  Widget build(BuildContext context) {
    final scaledBody = MediaQuery.textScalerOf(context).scale(16);
    final addedHeight = ((scaledBody - 16) * 10).clamp(0, 90).toDouble();
    return InkWell(
      key: const Key('social-open-short'),
      onTap: () => _showSocialDetailSheet(
        context,
        title: title,
        description: copy,
        primaryLabel: badge == 'YouTube' ? 'Play video' : 'Open',
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 330 + addedHeight,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: MoolColors.navy),
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C2A80), Color(0xFF11764F), Color(0xFF04104E)],
            stops: [0, .6, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 28,
              top: 28,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xE6FF9933), Color(0x00FF9933)],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_VideoBadge(badge), _VideoBadge(secondBadge)],
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x38000000),
                          blurRadius: 32,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: MoolColors.navy,
                      size: 32,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  copy,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({
    required this.icon,
    required this.title,
    required this.copy,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String copy;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: MoolColors.navy),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0x1F138808),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MoolColors.success, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  copy,
                  style: const TextStyle(
                    color: Color(0xFF31456A),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: actions.map((action) {
                    return Semantics(
                      button: true,
                      label: '$action for $title',
                      child: Material(
                        color: Colors.white,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          key: Key(
                            'card-action-${_keyPart(title)}-${_keyPart(action)}',
                          ),
                          onTap: () => _showSocialDetailSheet(
                            context,
                            title: '$action · $title',
                            description:
                                'Continue with $action. You can review the '
                                'result or cancel before anything is posted.',
                            primaryLabel: action,
                          ),
                          customBorder: const StadiumBorder(),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: MoolMetrics.minimumTapTarget,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0x3D000080),
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              action,
                              style: const TextStyle(
                                color: MoolColors.navy,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentActionRail extends StatefulWidget {
  const _ContentActionRail({required this.tab});

  final String tab;

  @override
  State<_ContentActionRail> createState() => _ContentActionRailState();
}

class _ContentActionRailState extends State<_ContentActionRail> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final actions = switch (widget.tab) {
      'Videos' => [
        ('Like', Icons.thumb_up_alt_outlined),
        ('Comments', Icons.chat_bubble_outline_rounded),
        ('Share', Icons.ios_share_rounded),
        ('Follow', Icons.person_add_alt_1_rounded),
        ('Save', Icons.bookmark_border_rounded),
        ('More', Icons.more_horiz_rounded),
      ],
      'Feed' => [
        ('Like', Icons.thumb_up_alt_outlined),
        ('Reply', Icons.chat_bubble_outline_rounded),
        ('Repost', Icons.repeat_rounded),
        ('Share', Icons.ios_share_rounded),
        ('Save', Icons.bookmark_border_rounded),
        ('Profile', Icons.person_outline_rounded),
      ],
      'Create' => [
        ('Post', Icons.arrow_forward_rounded),
        ('Upload', Icons.file_upload_outlined),
        ('Help', Icons.help_outline_rounded),
      ],
      _ => [
        ('Follow', Icons.person_add_alt_1_rounded),
        ('Like', Icons.thumb_up_alt_outlined),
        ('Comments', Icons.chat_bubble_outline_rounded),
        ('Share', Icons.ios_share_rounded),
        ('Remix', Icons.repeat_rounded),
        ('Save', Icons.bookmark_border_rounded),
        ('More', Icons.more_horiz_rounded),
      ],
    };
    return Column(
      children: actions.map((action) {
        final id = action.$1.toLowerCase();
        final selected = _selected.contains(id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: InkWell(
            key: Key('social-action-$id'),
            onTap: () {
              if (id == 'like' || id == 'save' || id == 'follow') {
                setState(() {
                  if (!selected) {
                    _selected.add(id);
                  } else {
                    _selected.remove(id);
                  }
                });
                return;
              }
              _showSocialDetailSheet(
                context,
                title: action.$1,
                description: switch (id) {
                  'comments' || 'reply' =>
                    'Write a useful response. You can cancel before sending.',
                  'share' =>
                    'Choose where to share this content. Nothing is sent '
                        'until you choose a destination.',
                  'remix' =>
                    'Choose the part you want to remix, add your own content '
                        'and review before posting.',
                  'repost' =>
                    'Add an optional comment and review before reposting.',
                  'profile' =>
                    'Open the creator profile, connected videos and available '
                        'MoolSocial actions.',
                  'more' =>
                    'Choose report, hide, copy link or view content details.',
                  'post' => 'Review the content and audience before posting.',
                  'upload' =>
                    'Choose an eligible photo or file and review it before '
                        'uploading.',
                  _ => 'Choose the next step or cancel.',
                },
                primaryLabel: switch (id) {
                  'comments' || 'reply' => 'Write reply',
                  'share' => 'Choose destination',
                  'remix' => 'Start remix',
                  'repost' => 'Review repost',
                  'profile' => 'Open profile',
                  'more' => 'Choose action',
                  'post' => 'Review post',
                  'upload' => 'Choose file',
                  _ => 'Continue',
                },
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                child: Container(
                  width: MoolMetrics.minimumTapTarget,
                  constraints: const BoxConstraints(minHeight: 52),
                  decoration: BoxDecoration(
                    color: selected
                        ? MoolColors.navy.withValues(alpha: .94)
                        : Colors.white.withValues(alpha: .90),
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000080),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected && id == 'like'
                            ? Icons.thumb_up_alt_rounded
                            : selected && id == 'save'
                            ? Icons.bookmark_rounded
                            : selected && id == 'follow'
                            ? Icons.person_rounded
                            : action.$2,
                        color: selected ? Colors.white : MoolColors.navy,
                        size: 18,
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          action.$1,
                          maxLines: 1,
                          style: TextStyle(
                            color: selected ? Colors.white : MoolColors.navy,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WorldSurface extends StatelessWidget {
  const _WorldSurface({
    required this.section,
    required this.selectedSubAction,
    required this.returnSection,
    required this.onSubActionChanged,
    super.key,
  });

  final String section;
  final String? selectedSubAction;
  final String returnSection;
  final ValueChanged<String> onSubActionChanged;

  @override
  Widget build(BuildContext context) {
    final specs = UniversalIntentCatalog.forSection(section);
    if (specs.isEmpty) return const SizedBox.shrink();
    final selected = UniversalIntentCatalog.selected(
      section,
      selectedSubAction,
    );
    return ListView(
      key: Key('section-$section'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
      children: [
        if (section == 'chat') ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('chat-return'),
              onPressed: () => context.go('/app/$returnSection'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text('Back to ${_titleCase(returnSection)}'),
            ),
          ),
          const SizedBox(height: 4),
        ],
        _FocusedSubActionStrip(
          section: section,
          specs: specs,
          selectedId: selected.id,
          onChanged: onSubActionChanged,
        ),
        const SizedBox(height: 12),
        _IntentEntryCard(spec: selected),
      ],
    );
  }
}

class _FocusedSubActionStrip extends StatelessWidget {
  const _FocusedSubActionStrip({
    required this.section,
    required this.specs,
    required this.selectedId,
    required this.onChanged,
  });

  final String section;
  final List<UniversalIntentSpec> specs;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${_titleCase(section)} choices',
      child: SizedBox(
        height: MoolMetrics.minimumTapTarget,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: specs.length,
          separatorBuilder: (_, _) => const SizedBox(width: MoolSpacing.xs),
          itemBuilder: (context, index) {
            final spec = specs[index];
            return MoolSegment(
              key: Key('sub-action-$section-${spec.id}'),
              label: spec.label,
              selected: spec.id == selectedId,
              onPressed: () => onChanged(spec.id),
            );
          },
        ),
      ),
    );
  }
}

class _IntentEntryCard extends StatelessWidget {
  const _IntentEntryCard({required this.spec});

  final UniversalIntentSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('intent-card-${spec.id}'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x26000080)),
        borderRadius: BorderRadius.circular(MoolRadii.card),
        boxShadow: MoolShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0x16138808),
                  shape: BoxShape.circle,
                ),
                child: Icon(spec.icon, color: MoolColors.success),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 19,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.25,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      spec.description,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: spec.facts
                .map(
                  (fact) => Chip(
                    label: Text(fact),
                    avatar: const Icon(
                      Icons.check_circle_rounded,
                      color: MoolColors.success,
                      size: 16,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: Key('open-intent-${spec.id}'),
            onPressed: () {
              final productionRoute = switch ((spec.section, spec.id)) {
                ('buy', 'grocery') ||
                ('buy', 'categories') => '/app/buy/grocery',
                ('buy', 'basket') => '/app/buy/basket',
                _ => null,
              };
              if (productionRoute != null) {
                context.go(productionRoute);
                return;
              }
              showIntentCompletionSheet(context, spec);
            },
            style: FilledButton.styleFrom(backgroundColor: MoolColors.navy),
            child: Text(spec.primaryAction),
          ),
        ],
      ),
    );
  }
}

class _UniversalDock extends StatelessWidget {
  const _UniversalDock({
    required this.session,
    required this.activeSection,
    required this.moolOpen,
  });

  final JourneySession session;
  final String activeSection;
  final bool moolOpen;

  @override
  Widget build(BuildContext context) {
    return MoolGlassSurface(
      key: const Key('universal-navigation'),
      dark: moolOpen,
      semanticLabel: moolOpen ? 'Mool actions open' : 'MoolSocial navigation',
      padding: EdgeInsets.all(moolOpen ? 6 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MoolButton(
            key: Key(moolOpen ? 'close-mool' : 'nav-mool'),
            active: moolOpen,
            onTap: () {
              if (moolOpen) {
                context.go(session.closeMoolRoute());
              } else {
                session.openMoolFrom(activeSection);
                context.go('/app/mool');
              }
            },
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _FocusedDockButton(
              activeSection: activeSection,
              moolOpen: moolOpen,
            ),
          ),
          const SizedBox(width: 7),
          _ChatButton(
            active: activeSection == 'chat' && !moolOpen,
            darkMode: moolOpen,
            onTap: () {
              if (activeSection != 'chat') {
                session.openMoolFrom(activeSection);
              }
              final current = GoRouterState.of(context).uri.toString();
              context.go(
                Uri(
                  path: '/app/chat/inbox',
                  queryParameters: {'return': current},
                ).toString(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MoolButton extends StatelessWidget {
  const _MoolButton({required this.active, required this.onTap, super.key});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: active ? 'Close Mool actions' : 'Open Mool actions',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFFFC47C), MoolColors.orange],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2020C8), Color(0xFF08086F)],
                  ),
            border: Border.all(color: Colors.white38),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(
                color: Color(0x47070868),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            'Mool',
            style: TextStyle(
              color: active ? MoolColors.navy : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusedDockButton extends StatelessWidget {
  const _FocusedDockButton({
    required this.activeSection,
    required this.moolOpen,
  });

  final String activeSection;
  final bool moolOpen;

  @override
  Widget build(BuildContext context) {
    final icon = _mainActionIcon(activeSection);
    final foreground = moolOpen ? Colors.white : MoolColors.navy;
    return Semantics(
      selected: !moolOpen,
      label: moolOpen
          ? 'Choose a Mool action above'
          : '${_titleCase(activeSection)} is open',
      child: Container(
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: MoolSpacing.md),
        decoration: BoxDecoration(
          color: moolOpen
              ? Colors.white.withValues(alpha: .08)
              : const Color(0xB8EEF0FA),
          border: Border.all(
            color: moolOpen ? Colors.white12 : const Color(0x14000080),
          ),
          borderRadius: BorderRadius.circular(MoolRadii.card),
        ),
        child: AnimatedSwitcher(
          duration: MoolMotion.accessible(context, MoolMotion.quick),
          child: Row(
            key: ValueKey('$activeSection-$moolOpen'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                moolOpen ? Icons.touch_app_outlined : icon,
                color: foreground,
                size: 19,
              ),
              const SizedBox(width: MoolSpacing.xs),
              Flexible(
                child: Text(
                  moolOpen ? 'Choose an action' : _titleCase(activeSection),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _ChatButton extends StatelessWidget {
  const _ChatButton({
    required this.active,
    required this.darkMode,
    required this.onTap,
  });

  final bool active;
  final bool darkMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active || darkMode ? Colors.white : MoolColors.navy;
    return Semantics(
      button: true,
      selected: active,
      label: 'Open Chat, 2 unread messages',
      child: InkWell(
        key: const Key('nav-chat'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: active
                ? MoolColors.navy
                : darkMode
                ? Colors.white.withValues(alpha: .10)
                : Colors.white.withValues(alpha: .86),
            border: Border.all(
              color: darkMode ? Colors.white24 : const Color(0x29000080),
            ),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Stack(
            children: [
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: foreground,
                        size: 17,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Chat',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 1,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: MoolColors.orange,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: MoolColors.navy,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
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

class _MoolCommandPalette extends StatelessWidget {
  const _MoolCommandPalette({required this.activeSection});

  final String activeSection;

  static const actions = [
    'social',
    'buy',
    'eat',
    'ride',
    'book',
    'pay',
    'work',
  ];

  @override
  Widget build(BuildContext context) {
    return MoolGlassSurface(
      key: const Key('mool-command-palette'),
      dark: true,
      semanticLabel: 'Choose a Mool action',
      borderRadius: MoolRadii.sheet,
      padding: const EdgeInsets.all(MoolSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to do?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Choose an action to see what you can do next.',
            style: TextStyle(
              color: Color(0xFFD9DAFF),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: MoolSpacing.xs,
            crossAxisSpacing: MoolSpacing.xs,
            childAspectRatio: .95,
            children: actions
                .map(
                  (action) => _MoolActionTile(
                    action: action,
                    selected: action == activeSection,
                    onTap: () => context.go('/app/$action'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MoolActionTile extends StatelessWidget {
  const _MoolActionTile({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  final String action;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Open ${_titleCase(action)}',
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(MoolRadii.card),
        child: InkWell(
          key: Key('mool-action-$action'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(MoolRadii.card),
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.xs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _mainActionIcon(action),
                    color: selected ? MoolColors.navy : Colors.white,
                    size: 23,
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  Text(
                    _titleCase(action),
                    style: TextStyle(
                      color: selected ? MoolColors.navy : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
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
}

IconData _mainActionIcon(String action) => switch (action) {
  'social' => Icons.play_circle_outline_rounded,
  'buy' => Icons.shopping_bag_outlined,
  'eat' => Icons.restaurant_outlined,
  'ride' => Icons.location_on_outlined,
  'book' => Icons.calendar_month_outlined,
  'pay' => Icons.account_balance_wallet_outlined,
  'work' => Icons.work_outline_rounded,
  'chat' => Icons.chat_bubble_outline_rounded,
  _ => Icons.circle_outlined,
};

String _titleCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _keyPart(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

enum _QuickInputType { scan, voice }

Future<void> _showQuickInputSheet(
  BuildContext context, {
  required _QuickInputType type,
}) async {
  final value = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _QuickInputSheet(type: type),
  );
  if (value == null || !context.mounted) return;
  context.go(
    type == _QuickInputType.scan
        ? '/app/pay?sub=scan-pay'
        : _routeForQuery(value),
  );
}

class _QuickInputSheet extends StatefulWidget {
  const _QuickInputSheet({required this.type});

  final _QuickInputType type;

  @override
  State<_QuickInputSheet> createState() => _QuickInputSheetState();
}

class _QuickInputSheetState extends State<_QuickInputSheet> {
  final _controller = TextEditingController();
  var _error = '';
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useCamera() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final result = await _showCameraScanner(context);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result != null) {
        _controller
          ..text = result
          ..selection = TextSelection.collapsed(offset: result.length);
      }
    });
  }

  Future<void> _useVoice() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final result = await _captureVoiceQuery(context);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result != null) {
        _controller
          ..text = result
          ..selection = TextSelection.collapsed(offset: result.length);
      }
    });
  }

  void _continue() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _error = widget.type == _QuickInputType.scan
            ? 'Enter or scan a code to continue.'
            : 'Enter or say what you want to find.';
      });
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.type == _QuickInputType.scan;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.xs,
        MoolSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            scan ? Icons.qr_code_scanner_rounded : Icons.mic_none_rounded,
            color: MoolColors.navy,
            size: 44,
          ),
          const SizedBox(height: MoolSpacing.md),
          Text(
            scan ? 'Scan or enter a code' : 'Search by voice or text',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            scan
                ? 'Use the camera only when you choose Scan with camera, or '
                      'enter a supported payment or MoolSocial code.'
                : 'Use the microphone only when you choose Start listening, '
                      'or type the same request.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          OutlinedButton.icon(
            key: Key(scan ? 'scan-with-camera' : 'start-voice-search'),
            onPressed: _busy ? null : (scan ? _useCamera : _useVoice),
            icon: Icon(scan ? Icons.camera_alt_outlined : Icons.mic_rounded),
            label: Text(
              _busy
                  ? 'Opening…'
                  : scan
                  ? 'Scan with camera'
                  : 'Start listening',
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          TextField(
            key: Key(scan ? 'scan-code-field' : 'voice-search-field'),
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _continue(),
            onChanged: (_) {
              if (_error.isNotEmpty) setState(() => _error = '');
            },
            decoration: InputDecoration(
              labelText: scan ? 'Code or payment ID' : 'What do you need?',
              prefixIcon: Icon(
                scan ? Icons.qr_code_rounded : Icons.search_rounded,
              ),
              errorText: _error.isEmpty ? null : _error,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: Key(scan ? 'continue-scan' : 'continue-voice-search'),
            onPressed: _busy ? null : _continue,
            style: FilledButton.styleFrom(backgroundColor: MoolColors.navy),
            child: Text(scan ? 'Review payment code' : 'Show results'),
          ),
          TextButton(
            key: Key(scan ? 'cancel-scan' : 'cancel-voice-search'),
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

Future<String?> _showCameraScanner(BuildContext context) async {
  final permission = await Permission.camera.request();
  if (!permission.isGranted) {
    if (context.mounted) {
      await _showPermissionRecovery(
        context,
        title: 'Camera access is off',
        description:
            'Allow camera access in device settings to scan a code, or enter '
            'the code instead.',
        settingsKey: 'open-camera-settings',
      );
    }
    return null;
  }
  if (!context.mounted) return null;

  var handled = false;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.black,
    builder: (scannerContext) => SizedBox(
      height: MediaQuery.sizeOf(scannerContext).height * .82,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (handled || capture.barcodes.isEmpty) return;
              final value = capture.barcodes.first.rawValue?.trim();
              if (value == null || value.isEmpty) return;
              handled = true;
              Navigator.pop(scannerContext, value);
            },
          ),
          Center(
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(MoolRadii.card),
                ),
              ),
            ),
          ),
          Positioned(
            top: MoolSpacing.md,
            left: MoolSpacing.md,
            right: MoolSpacing.md,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Place the code inside the frame',
                    style: Theme.of(scannerContext).textTheme.titleMedium
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('close-camera-scanner'),
                  onPressed: () => Navigator.pop(scannerContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Future<String?> _captureVoiceQuery(BuildContext context) async {
  final speech = SpeechToText();
  final available = await speech.initialize();
  if (!available) {
    if (context.mounted) {
      await _showPermissionRecovery(
        context,
        title: 'Voice search is unavailable',
        description:
            'Allow microphone and speech access in device settings, or type '
            'your search instead.',
        settingsKey: 'open-microphone-settings',
      );
    }
    return null;
  }
  if (!context.mounted) return null;

  String words = '';
  var listening = false;
  try {
    return await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (voiceContext) => StatefulBuilder(
        builder: (context, setVoiceState) => Padding(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            MoolSpacing.xs,
            MoolSpacing.lg,
            MoolSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mic_rounded, size: 54, color: MoolColors.navy),
              const SizedBox(height: MoolSpacing.md),
              Text(
                words.isEmpty
                    ? listening
                          ? 'Listening…'
                          : 'Tap Listen and say what you need'
                    : words,
                key: const Key('recognized-voice-query'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.lg),
              OutlinedButton.icon(
                key: const Key('listen-for-query'),
                onPressed: listening
                    ? () async {
                        await speech.stop();
                        if (voiceContext.mounted) {
                          setVoiceState(() => listening = false);
                        }
                      }
                    : () async {
                        setVoiceState(() => listening = true);
                        await speech.listen(
                          onResult: (result) {
                            if (!voiceContext.mounted) return;
                            setVoiceState(() {
                              words = result.recognizedWords;
                              if (result.finalResult) listening = false;
                            });
                          },
                        );
                      },
                icon: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(listening ? 'Stop listening' : 'Listen'),
              ),
              FilledButton(
                key: const Key('use-voice-query'),
                onPressed: words.trim().isEmpty
                    ? null
                    : () => Navigator.pop(voiceContext, words.trim()),
                child: const Text('Use this search'),
              ),
              TextButton(
                key: const Key('cancel-voice-capture'),
                onPressed: () => Navigator.pop(voiceContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  } finally {
    await speech.cancel();
  }
}

Future<void> _showPermissionRecovery(
  BuildContext context, {
  required String title,
  required String description,
  required String settingsKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.xs,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            description,
            style: const TextStyle(color: MoolColors.muted, height: 1.4),
          ),
          const SizedBox(height: MoolSpacing.lg),
          FilledButton(
            key: Key(settingsKey),
            onPressed: () async {
              await openAppSettings();
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
            child: const Text('Open device settings'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Use keyboard instead'),
          ),
        ],
      ),
    ),
  );
}

String _routeForQuery(String value) {
  final query = value.toLowerCase();
  if (query.contains('medicine') || query.contains('pharmacy')) {
    return '/app/buy?sub=medicine';
  }
  if (query.contains('basket')) return '/app/buy?sub=basket';
  if (query.contains('grocery')) return '/app/buy?sub=grocery';
  if (query.contains('tiffin')) return '/app/eat?sub=tiffin';
  if (query.contains('table')) return '/app/eat?sub=book-table';
  if (query.contains('doctor')) return '/app/book?sub=doctor';
  if (query.contains('salon')) return '/app/book?sub=salon';
  if (query.contains('recharge')) return '/app/pay?sub=recharge';
  if (query.contains('bill')) return '/app/pay?sub=bills';
  if (query.contains('receipt')) return '/app/pay?sub=receipts';
  if (query.contains('delivery work')) return '/app/work?sub=delivery';
  if (query.contains('onboard')) return '/app/work?sub=onboard';
  if (query.contains('verify')) return '/app/work?sub=verify';
  if (query.contains('workspace')) return '/app/work?sub=workspace';
  if (query.contains('business chat')) return '/app/chat?sub=business-chat';
  if (query.contains('support')) return '/app/chat?sub=support';
  if (query.contains('order chat')) return '/app/chat?sub=orders';
  if (query.contains('auto')) return '/app/ride?sub=auto';
  if (query.contains('cab')) return '/app/ride?sub=cab';
  if (query.contains('bike')) return '/app/ride?sub=bike';
  if (query.contains('food') ||
      query.contains('restaurant') ||
      query.contains('tiffin')) {
    return '/app/eat';
  }
  if (query.contains('ride') ||
      query.contains('bike') ||
      query.contains('auto') ||
      query.contains('cab')) {
    return '/app/ride';
  }
  if (query.contains('doctor') ||
      query.contains('salon') ||
      query.contains('book')) {
    return '/app/book';
  }
  if (query.contains('pay') ||
      query.contains('bill') ||
      query.contains('recharge')) {
    return '/app/pay';
  }
  if (query.contains('work') ||
      query.contains('earn') ||
      query.contains('job')) {
    return '/app/work';
  }
  if (query.contains('chat') || query.contains('message')) return '/app/chat';
  if (query.contains('buy') ||
      query.contains('grocery') ||
      query.contains('medicine') ||
      query.contains('product')) {
    return '/app/buy';
  }
  return '/app/social';
}

Future<void> _showSocialDetailSheet(
  BuildContext context, {
  required String title,
  required String description,
  required String primaryLabel,
}) {
  final actionKey = _keyPart(primaryLabel);
  final options = _socialActionOptions(actionKey);
  final requiresText = const {
    'write-reply',
    'comment',
    'caption',
    'text',
  }.contains(actionKey);
  var continued = false;
  var input = '';
  String? selectedOption;
  var error = '';
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          MoolSpacing.xs,
          MoolSpacing.lg,
          MoolSpacing.lg,
        ),
        child: AnimatedSwitcher(
          duration: MoolMotion.accessible(context, MoolMotion.standard),
          child: continued
              ? Column(
                  key: const ValueKey('result'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: MoolColors.success,
                      size: 60,
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    Text(
                      _socialCompletionTitle(actionKey),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      _socialCompletionDescription(
                        actionKey,
                        selectedOption: selectedOption,
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MoolColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: MoolSpacing.lg),
                    FilledButton(
                      key: Key('social-action-done-${_keyPart(primaryLabel)}'),
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: MoolColors.navy,
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                )
              : Column(
                  key: const ValueKey('details'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      description,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    if (options.isNotEmpty) ...[
                      const SizedBox(height: MoolSpacing.md),
                      for (var index = 0; index < options.length; index += 1)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: MoolSpacing.xs,
                          ),
                          child: Material(
                            color: selectedOption == options[index]
                                ? const Color(0xFFE9EBFF)
                                : const Color(0xFFF5F6FC),
                            borderRadius: BorderRadius.circular(
                              MoolRadii.control,
                            ),
                            child: InkWell(
                              key: Key(
                                'social-action-option-$actionKey-$index',
                              ),
                              onTap: () => setSheetState(() {
                                selectedOption = options[index];
                                error = '';
                              }),
                              borderRadius: BorderRadius.circular(
                                MoolRadii.control,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: MoolMetrics.minimumTapTarget,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: MoolSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(options[index])),
                                      if (selectedOption == options[index])
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: MoolColors.success,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (requiresText) ...[
                      const SizedBox(height: MoolSpacing.md),
                      TextFormField(
                        key: Key('social-action-input-$actionKey'),
                        autofocus: true,
                        minLines: 2,
                        maxLines: 4,
                        onChanged: (value) {
                          input = value;
                          if (error.isNotEmpty) {
                            setSheetState(() => error = '');
                          }
                        },
                        decoration: InputDecoration(
                          labelText: actionKey == 'caption'
                              ? 'Caption'
                              : actionKey == 'text'
                              ? 'Post text'
                              : 'Reply',
                          hintText: actionKey == 'caption'
                              ? 'Describe this content'
                              : actionKey == 'text'
                              ? 'What would you like to share?'
                              : 'Write a useful response',
                        ),
                      ),
                    ],
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: MoolSpacing.xs),
                      Text(
                        error,
                        key: Key('social-action-error-$actionKey'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: MoolSpacing.lg),
                    FilledButton(
                      key: Key(
                        'social-action-continue-${_keyPart(primaryLabel)}',
                      ),
                      onPressed: () {
                        if (options.isNotEmpty && selectedOption == null) {
                          setSheetState(
                            () => error = 'Choose an option to continue.',
                          );
                          return;
                        }
                        if (requiresText && input.trim().isEmpty) {
                          setSheetState(
                            () => error = 'Enter text to continue.',
                          );
                          return;
                        }
                        setSheetState(() => continued = true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: MoolColors.navy,
                      ),
                      child: Text(_socialCommitLabel(actionKey, primaryLabel)),
                    ),
                    TextButton(
                      key: Key(
                        'social-action-cancel-${_keyPart(primaryLabel)}',
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

List<String> _socialActionOptions(String actionKey) {
  return switch (actionKey) {
    'choose-destination' => const ['MoolSocial chat', 'Copy link', 'More apps'],
    'choose-action' => const ['View details', 'Hide this content', 'Report'],
    'choose-file' => const ['Photo library', 'Document', 'Camera'],
    'record' => const ['Record now', 'Upload a clip'],
    'photo' => const ['Camera', 'Photo library'],
    'video' => const ['Connect YouTube video', 'Create Campaign Reel'],
    'proof' => const ['Photo proof', 'Document proof'],
    'area' => const ['Use current area', 'Choose another area'],
    _ => const [],
  };
}

String _socialCommitLabel(String actionKey, String fallback) {
  return switch (actionKey) {
    'write-reply' || 'comment' => 'Send reply',
    'caption' => 'Save caption',
    'text' => 'Review post',
    'choose-destination' => 'Share',
    'choose-action' => 'Continue',
    'choose-file' => 'Add file',
    'record' => 'Continue with video',
    'photo' => 'Add photo',
    'video' => 'Continue with video',
    'proof' => 'Add proof',
    'area' => 'Add area',
    _ => fallback,
  };
}

String _socialCompletionTitle(String actionKey) {
  return switch (actionKey) {
    'write-reply' || 'comment' => 'Reply sent',
    'caption' => 'Caption saved',
    'text' => 'Post is ready to review',
    'choose-destination' => 'Content shared',
    'choose-action' => 'Action completed',
    'choose-file' => 'File added',
    'record' => 'Video is ready to edit',
    'photo' => 'Photo added',
    'video' => 'Video connection is ready',
    'proof' => 'Proof added',
    'area' => 'Area added',
    'play-video' || 'open-connected-video' => 'Video opened',
    'follow' => 'Creator followed',
    'save' => 'Saved',
    _ => 'Action completed',
  };
}

String _socialCompletionDescription(
  String actionKey, {
  String? selectedOption,
}) {
  final choice = selectedOption == null ? '' : ' $selectedOption was chosen.';
  return switch (actionKey) {
    'write-reply' ||
    'comment' => 'Your reply appears with the conversation and delivery state.',
    'choose-destination' => 'The selected sharing action completed.$choice',
    'choose-file' || 'photo' || 'proof' =>
      'The selected content is attached and can be reviewed before posting.$choice',
    'record' || 'video' =>
      'Continue editing before publishing. Nothing is public yet.$choice',
    'caption' ||
    'text' ||
    'area' => 'Review the full post and audience before publishing.$choice',
    'play-video' || 'open-connected-video' =>
      'Playback is open with YouTube hosting clearly identified.',
    _ => 'The selected action completed.$choice',
  };
}

Future<void> _showProfile(BuildContext context, JourneySession session) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final area = switch (session.areaChoice) {
          AreaChoice.current => 'Current location',
          AreaChoice.manual => session.manualArea ?? 'Manual area',
          AreaChoice.skipped || null => 'Not set',
        };
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your account',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.person_rounded),
                  ),
                  title: Text('MoolSocial member'),
                  subtitle: Text('Your purchases, bookings and work stay here'),
                ),
                ListTile(
                  key: const Key('profile-language'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Language'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(session.languageCode == 'hi' ? 'हिन्दी' : 'English'),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: session.busy
                      ? null
                      : () => _showLanguagePicker(context, session),
                ),
                ListTile(
                  key: const Key('profile-area'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Service area'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(area, overflow: TextOverflow.ellipsis),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: session.busy
                      ? null
                      : () => _showAreaPicker(context, session),
                ),
                ListTile(
                  key: const Key('profile-workspace'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_rounded),
                  title: const Text('Business and workspaces'),
                  subtitle: const Text('Start or manage verified work'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/app/work');
                  },
                ),
                if (session.errorMessage case final message?)
                  Text(
                    message,
                    key: const Key('profile-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                OutlinedButton(
                  key: const Key('sign-out'),
                  onPressed: session.busy
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Sign out?'),
                              content: const Text(
                                'Your language and area will remain saved on '
                                'this device.',
                              ),
                              actions: [
                                TextButton(
                                  key: const Key('cancel-sign-out'),
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Stay signed in'),
                                ),
                                FilledButton(
                                  key: const Key('confirm-sign-out'),
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Sign out'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed ?? false) await session.signOut();
                        },
                  child: const Text('Sign out'),
                ),
                TextButton(
                  key: const Key('close-profile'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _showLanguagePicker(BuildContext context, JourneySession session) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose language',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final choice in const [('en', 'English'), ('hi', 'हिन्दी')])
            ListTile(
              key: Key('profile-language-${choice.$1}'),
              title: Text(choice.$2),
              trailing: session.languageCode == choice.$1
                  ? const Icon(Icons.check_circle, color: MoolColors.success)
                  : null,
              onTap: () async {
                final saved = await session.updateLanguage(choice.$1);
                if (saved && sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showAreaPicker(BuildContext context, JourneySession session) {
  var input = session.manualArea ?? '';
  var manual = false;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => AnimatedBuilder(
        animation: session,
        builder: (context, _) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose service area',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your area helps show nearby delivery, rides and work.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: 12),
              if (manual) ...[
                TextFormField(
                  key: const Key('profile-area-field'),
                  initialValue: input,
                  autofocus: true,
                  onChanged: (value) => input = value,
                  decoration: const InputDecoration(
                    labelText: 'Area or PIN code',
                    hintText: 'For example, Sardarpura',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('profile-area-save'),
                  onPressed: session.busy
                      ? null
                      : () async {
                          final saved = await session.updateArea(
                            AreaChoice.manual,
                            label: input,
                          );
                          if (saved && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                  child: const Text('Save service area'),
                ),
                TextButton(
                  onPressed: () => setSheetState(() => manual = false),
                  child: const Text('Back'),
                ),
              ] else ...[
                ListTile(
                  key: const Key('profile-area-current'),
                  leading: const Icon(Icons.my_location_rounded),
                  title: const Text('Use current location'),
                  onTap: session.busy
                      ? null
                      : () async {
                          await session.useCurrentLocation();
                          if (session.areaChoice == AreaChoice.current) {
                            final saved = await session.updateArea(
                              AreaChoice.current,
                            );
                            if (saved && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          }
                        },
                ),
                ListTile(
                  key: const Key('profile-area-manual'),
                  leading: const Icon(Icons.edit_location_alt_rounded),
                  title: const Text('Enter area or PIN code'),
                  onTap: () => setSheetState(() => manual = true),
                ),
                ListTile(
                  key: const Key('profile-area-remove'),
                  leading: const Icon(Icons.location_off_outlined),
                  title: const Text('Remove service area'),
                  onTap: session.busy
                      ? null
                      : () async {
                          final saved = await session.updateArea(
                            AreaChoice.skipped,
                          );
                          if (saved && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                ),
                if (session.errorMessage case final message?) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    key: const Key('profile-area-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showSearch(BuildContext context) {
  final actions = <(String, String, IconData, String, String?, String)>[
    (
      'Buy products',
      'Home delivery and local shops',
      Icons.shopping_bag,
      'buy',
      null,
      'buy',
    ),
    (
      'Find work',
      'Funded verified opportunities',
      Icons.work,
      'work',
      null,
      'work',
    ),
    (
      'Open chat',
      'People and business conversations',
      Icons.chat,
      'chat',
      null,
      'chat',
    ),
    (
      'Order food',
      'Food, tables and tiffin',
      Icons.restaurant,
      'eat',
      null,
      'eat',
    ),
    (
      'Book a ride',
      'Local pickup and travel',
      Icons.directions_car,
      'ride',
      null,
      'ride',
    ),
    (
      'Book services',
      'Appointments and services',
      Icons.calendar_month,
      'book',
      null,
      'book',
    ),
    (
      'Pay',
      'Payments and receipts',
      Icons.account_balance_wallet,
      'pay',
      null,
      'pay',
    ),
    for (final entry in UniversalIntentCatalog.bySection.entries)
      for (final spec in entry.value)
        (
          spec.label,
          spec.description,
          spec.icon,
          entry.key,
          spec.id,
          '${entry.key}-${spec.id}',
        ),
  ];
  var query = '';

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final normalized = query.trim().toLowerCase();
        final matches = actions
            .where(
              (action) =>
                  normalized.isEmpty ||
                  action.$1.toLowerCase().contains(normalized) ||
                  action.$2.toLowerCase().contains(normalized),
            )
            .toList();
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Search MoolSocial',
                  style: TextStyle(
                    color: MoolColors.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('search-field'),
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'What do you want to get done?',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => setSheetState(() => query = value),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: matches.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(MoolSpacing.lg),
                            child: Text(
                              'No matching action. Try a product, service, '
                              'ride, payment, work or person.',
                              key: Key('search-empty'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: MoolColors.muted,
                                height: 1.45,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final action = matches[index];
                            return ListTile(
                              key: Key('search-result-${action.$6}'),
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(action.$3, color: MoolColors.navy),
                              title: Text(action.$1),
                              subtitle: Text(action.$2),
                              trailing: const Icon(Icons.arrow_forward_rounded),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                final subAction = action.$5;
                                context.go(
                                  subAction == null
                                      ? '/app/${action.$4}'
                                      : '/app/${action.$4}?sub=$subAction',
                                );
                              },
                            );
                          },
                        ),
                ),
                TextButton(
                  key: const Key('close-search'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
