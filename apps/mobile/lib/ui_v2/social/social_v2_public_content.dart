import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../features/shared/shared_models.dart';
import '../../features/shared/shared_session.dart';
import 'social_v2_design.dart';

class SocialPublishedContentCardV2 extends StatelessWidget {
  const SocialPublishedContentCardV2({
    required this.item,
    required this.session,
    required this.onReply,
    required this.onShare,
    super.key,
  });

  final SocialPublishedItem item;
  final SharedSession session;
  final VoidCallback onReply;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return SocialV2Card(
      key: Key('social-public-${item.type.name}-${item.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PublicAuthorLine(item: item),
          if (item.body.isNotEmpty &&
              item.type != SocialPublishedContentType.reel)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Text(
                item.body,
                style: const TextStyle(
                  color: SocialV2Colors.ink,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          switch (item.type) {
            SocialPublishedContentType.carousel => _PublicCarousel(item: item),
            SocialPublishedContentType.post =>
              item.mediaPaths.isEmpty
                  ? const SizedBox.shrink()
                  : AspectRatio(
                      aspectRatio: 4 / 3,
                      child: SocialMediaPreviewV2(
                        path: item.mediaPaths.first,
                        isAsset: item.mediaAreAssets,
                        fit: BoxFit.cover,
                      ),
                    ),
            SocialPublishedContentType.imagePoll ||
            SocialPublishedContentType.quickPoll ||
            SocialPublishedContentType.quiz => _PublicPoll(
              item: item,
              session: session,
            ),
            SocialPublishedContentType.reel => const SizedBox.shrink(),
          },
          _PublicActionRow(
            item: item,
            session: session,
            onReply: onReply,
            onShare: onShare,
          ),
        ],
      ),
    );
  }
}

class SocialPublishedReelV2 extends StatefulWidget {
  const SocialPublishedReelV2({
    required this.item,
    required this.session,
    required this.onComment,
    required this.onShare,
    super.key,
  });

  final SocialPublishedItem item;
  final SharedSession session;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  State<SocialPublishedReelV2> createState() => _SocialPublishedReelV2State();
}

class _SocialPublishedReelV2State extends State<SocialPublishedReelV2> {
  VideoPlayerController? _controller;
  bool _chromeVisible = true;
  bool _expanded = false;
  bool _followed = false;

  @override
  void initState() {
    super.initState();
    _prepareVideo();
  }

  void _prepareVideo() {
    if (widget.item.mediaPaths.isEmpty || widget.item.mediaAreAssets) return;
    final controller = VideoPlayerController.file(
      File(widget.item.mediaPaths.first),
    );
    _controller = controller;
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final controller = _controller;
    return GestureDetector(
      key: Key('social-public-reel-${item.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _chromeVisible = !_chromeVisible),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.mediaAreAssets)
            SocialMediaPreviewV2(
              path: item.mediaPaths.first,
              isAsset: true,
              fit: BoxFit.cover,
            )
          else if (controller?.value.isInitialized == true)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller!.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            const ColoredBox(
              color: Color(0xFF05051F),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x22000020),
                  Color(0x11000020),
                  Color(0xE9000018),
                ],
                stops: [0, .45, 1],
              ),
            ),
          ),
          if (_chromeVisible)
            Center(
              child: Semantics(
                button: true,
                label: controller?.value.isPlaying == true
                    ? 'Pause Reel'
                    : 'Play Reel',
                child: IconButton.filled(
                  key: const Key('social-public-reel-play'),
                  onPressed: _togglePlayback,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(54),
                    backgroundColor: const Color(0xB0000048),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x66FFFFFF)),
                  ),
                  icon: Icon(
                    controller?.value.isPlaying == true
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 30,
                  ),
                ),
              ),
            ),
          if (_chromeVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: SocialV2Colors.navy,
                          foregroundColor: Colors.white,
                          child: Text(
                            _initials(item.authorName),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.authorName}  ${item.authorHandle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              setState(() => _followed = !_followed),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            minimumSize: const Size(72, 44),
                          ),
                          child: Text(_followed ? 'Following' : 'Follow'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (item.body.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              item.body,
                              maxLines: _expanded ? null : 2,
                              overflow: _expanded
                                  ? null
                                  : TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _expanded = !_expanded),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(50, 44),
                            ),
                            child: Text(_expanded ? 'Less' : 'More'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    _PublicActionRow(
                      item: item,
                      session: widget.session,
                      onReply: widget.onComment,
                      onShare: widget.onShare,
                      dark: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SocialMediaPreviewV2 extends StatelessWidget {
  const SocialMediaPreviewV2({
    required this.path,
    required this.isAsset,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String path;
  final bool isAsset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (isAsset) return Image.asset(path, fit: fit);
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFF1F2FA),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: SocialV2Colors.muted,
          ),
        ),
      ),
    );
  }
}

class _PublicAuthorLine extends StatelessWidget {
  const _PublicAuthorLine({required this.item});

  final SocialPublishedItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: SocialV2Colors.navy,
            foregroundColor: Colors.white,
            child: Text(
              _initials(item.authorName),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${item.authorHandle} · Just now · ${item.audience}',
                  maxLines: 1,
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
        ],
      ),
    );
  }
}

class _PublicCarousel extends StatefulWidget {
  const _PublicCarousel({required this.item});

  final SocialPublishedItem item;

  @override
  State<_PublicCarousel> createState() => _PublicCarouselState();
}

class _PublicCarouselState extends State<_PublicCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.03,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            key: Key('social-public-carousel-pages-${widget.item.id}'),
            itemCount: widget.item.mediaPaths.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (_, index) => SocialMediaPreviewV2(
              path: widget.item.mediaPaths[index],
              isAsset: widget.item.mediaAreAssets,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xB0000018),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${_page + 1} / ${widget.item.mediaPaths.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (
                  var index = 0;
                  index < widget.item.mediaPaths.length;
                  index++
                )
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: index == _page ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? SocialV2Colors.saffron
                          : Colors.white,
                      borderRadius: BorderRadius.circular(99),
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

class _PublicPoll extends StatelessWidget {
  const _PublicPoll({required this.item, required this.session});

  final SocialPublishedItem item;
  final SharedSession session;

  @override
  Widget build(BuildContext context) {
    final imagePoll = item.type == SocialPublishedContentType.imagePoll;
    final quiz = item.type == SocialPublishedContentType.quiz;
    final answered = item.selectedChoiceIndex != null;
    final total = item.voteCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imagePoll)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: .84,
              ),
              itemCount: item.choices.length,
              itemBuilder: (_, index) => _ImagePollChoice(
                item: item,
                index: index,
                onTap: () => session.voteOnSocialContent(item.id, index),
              ),
            )
          else
            for (var index = 0; index < item.choices.length; index++) ...[
              _TextPollChoice(
                item: item,
                index: index,
                quiz: quiz,
                onTap: () => session.voteOnSocialContent(item.id, index),
              ),
              if (index + 1 < item.choices.length) const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          Text(
            answered
                ? '$total ${total == 1 ? 'vote' : 'votes'} · ${quiz ? 'Answer shown' : 'Results shown'}'
                : '${quiz ? 'Choose one answer' : 'Choose one option'} · Closes in 7 days',
            style: const TextStyle(
              color: SocialV2Colors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePollChoice extends StatelessWidget {
  const _ImagePollChoice({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final SocialPublishedItem item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final choice = item.choices[index];
    final selected = item.selectedChoiceIndex == index;
    final total = item.voteCount;
    final percent = total == 0 ? 0 : (choice.votes * 100 / total).round();
    return InkWell(
      key: Key('social-public-${item.id}-choice-$index'),
      onTap: item.selectedChoiceIndex == null ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? const Color(0x10138808) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? SocialV2Colors.green : SocialV2Colors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: SocialMediaPreviewV2(
                  path: choice.imagePath!,
                  isAsset: choice.imageIsAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      choice.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SocialV2Colors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (item.selectedChoiceIndex != null)
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: SocialV2Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextPollChoice extends StatelessWidget {
  const _TextPollChoice({
    required this.item,
    required this.index,
    required this.quiz,
    required this.onTap,
  });

  final SocialPublishedItem item;
  final int index;
  final bool quiz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final choice = item.choices[index];
    final answered = item.selectedChoiceIndex != null;
    final selected = item.selectedChoiceIndex == index;
    final correct = quiz && item.correctChoiceIndex == index;
    final total = item.voteCount;
    final percent = total == 0 ? 0 : (choice.votes * 100 / total).round();
    final border = answered && correct
        ? SocialV2Colors.green
        : selected
        ? SocialV2Colors.saffron
        : SocialV2Colors.line;
    return OutlinedButton(
      key: Key('social-public-${item.id}-choice-$index'),
      onPressed: answered ? null : onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        alignment: Alignment.centerLeft,
        side: BorderSide(
          color: border,
          width: answered && (selected || correct) ? 2 : 1,
        ),
        backgroundColor: answered && correct
            ? const Color(0x10138808)
            : selected
            ? const Color(0x10FF9933)
            : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              choice.label,
              style: const TextStyle(
                color: SocialV2Colors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (answered)
            Text(
              correct && quiz ? 'Correct' : '$percent%',
              style: TextStyle(
                color: correct ? SocialV2Colors.green : SocialV2Colors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _PublicActionRow extends StatelessWidget {
  const _PublicActionRow({
    required this.item,
    required this.session,
    required this.onReply,
    required this.onShare,
    this.dark = false,
  });

  final SocialPublishedItem item;
  final SharedSession session;
  final VoidCallback onReply;
  final VoidCallback onShare;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? Colors.white : SocialV2Colors.navy;
    return Padding(
      padding: dark ? EdgeInsets.zero : const EdgeInsets.fromLTRB(6, 2, 6, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PublicIconAction(
            key: Key('social-public-like-${item.id}'),
            icon: item.liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: item.likeCount == 0 ? 'Like' : '${item.likeCount}',
            color: color,
            onTap: () => session.toggleSocialLike(item.id),
          ),
          _PublicIconAction(
            icon: Icons.chat_bubble_outline_rounded,
            label: item.replyCount == 0 ? 'Reply' : '${item.replyCount}',
            color: color,
            onTap: () {
              session.recordSocialReply(item.id);
              onReply();
            },
          ),
          _PublicIconAction(
            icon: Icons.repeat_rounded,
            label: item.repostCount == 0 ? 'Repost' : '${item.repostCount}',
            color: color,
            onTap: () => session.recordSocialRepost(item.id),
          ),
          _PublicIconAction(
            icon: Icons.share_outlined,
            label: item.shareCount == 0 ? 'Share' : '${item.shareCount}',
            color: color,
            onTap: () {
              session.recordSocialShare(item.id);
              onShare();
            },
          ),
          _PublicIconAction(
            key: Key('social-public-save-${item.id}'),
            icon: item.saved
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: item.saved ? 'Saved' : 'Save',
            color: color,
            onTap: () => session.toggleSocialSave(item.id),
          ),
        ],
      ),
    );
  }
}

class _PublicIconAction extends StatelessWidget {
  const _PublicIconAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (parts.isEmpty) return 'MS';
  return parts.map((part) => part[0].toUpperCase()).join();
}
