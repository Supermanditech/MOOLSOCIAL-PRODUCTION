import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/shared/shared_models.dart';
import '../../features/shared/shared_session.dart';
import '../../features/shared/social_media_picker.dart';
import 'social_v2_design.dart';
import 'social_v2_public_content.dart';

enum SocialCreateFormatV2 { reel, carousel, post }

enum _SocialPostTool { none, image, imagePoll, quickPoll, quiz }

class SocialCreateWorkbenchV2 extends StatefulWidget {
  const SocialCreateWorkbenchV2({
    required this.session,
    required this.mediaPicker,
    required this.authorName,
    required this.authorHandle,
    required this.onPublished,
    this.initialFormat = SocialCreateFormatV2.post,
    super.key,
  });

  final SharedSession session;
  final SocialMediaPicker mediaPicker;
  final String authorName;
  final String authorHandle;
  final ValueChanged<SocialPublishedItem> onPublished;
  final SocialCreateFormatV2 initialFormat;

  @override
  State<SocialCreateWorkbenchV2> createState() =>
      _SocialCreateWorkbenchV2State();
}

class _SocialCreateWorkbenchV2State extends State<SocialCreateWorkbenchV2> {
  late SocialCreateFormatV2 _format;
  _SocialPostTool _postTool = _SocialPostTool.none;
  final TextEditingController _body = TextEditingController();
  final TextEditingController _firstChoice = TextEditingController();
  final TextEditingController _secondChoice = TextEditingController();
  final FocusNode _bodyFocus = FocusNode();
  final List<SocialPickedMedia> _media = <SocialPickedMedia>[];
  final List<SocialPickedMedia?> _imagePollMedia = <SocialPickedMedia?>[
    null,
    null,
  ];
  int _correctChoice = 0;
  bool _selectingMedia = false;

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_format == SocialCreateFormatV2.post) _bodyFocus.requestFocus();
      _recoverInterruptedSelection();
    });
  }

  @override
  void dispose() {
    _body.dispose();
    _firstChoice.dispose();
    _secondChoice.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _recoverInterruptedSelection() async {
    final recovered = await widget.mediaPicker.recoverInterruptedSelection();
    if (!mounted || recovered.isEmpty) return;
    setState(() {
      if (recovered.first.kind == SocialMediaKind.video) {
        _format = SocialCreateFormatV2.reel;
        _media
          ..clear()
          ..add(recovered.first);
      } else {
        _format = recovered.length > 1
            ? SocialCreateFormatV2.carousel
            : SocialCreateFormatV2.post;
        _postTool = recovered.length > 1
            ? _SocialPostTool.none
            : _SocialPostTool.image;
        _media
          ..clear()
          ..addAll(recovered.take(10));
      }
    });
  }

  Future<void> _selectFormat(SocialCreateFormatV2 format) async {
    HapticFeedback.selectionClick();
    setState(() {
      _format = format;
      if (format != SocialCreateFormatV2.post) _postTool = _SocialPostTool.none;
    });
    if (format == SocialCreateFormatV2.post) {
      _bodyFocus.requestFocus();
    } else if (format == SocialCreateFormatV2.carousel && _media.length < 2) {
      await _chooseCarousel();
    }
  }

  Future<void> _chooseReel(SocialMediaSource source) async {
    if (_selectingMedia) return;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickReel(source);
      if (!mounted || selected == null) return;
      setState(() {
        _media
          ..clear()
          ..add(selected);
      });
    } finally {
      if (mounted) setState(() => _selectingMedia = false);
    }
  }

  Future<void> _chooseCarousel() async {
    if (_selectingMedia) return;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickCarousel(limit: 10);
      if (!mounted || selected.isEmpty) return;
      setState(() {
        _media
          ..clear()
          ..addAll(selected.take(10));
      });
    } finally {
      if (mounted) setState(() => _selectingMedia = false);
    }
  }

  Future<void> _choosePostImage() async {
    if (_selectingMedia) return;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickImage(
        SocialMediaSource.gallery,
      );
      if (!mounted || selected == null) return;
      setState(() {
        _media
          ..clear()
          ..add(selected);
      });
    } finally {
      if (mounted) setState(() => _selectingMedia = false);
    }
  }

  Future<void> _chooseImagePollMedia(int index) async {
    if (_selectingMedia) return;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickImage(
        SocialMediaSource.gallery,
      );
      if (!mounted || selected == null) return;
      setState(() => _imagePollMedia[index] = selected);
    } finally {
      if (mounted) setState(() => _selectingMedia = false);
    }
  }

  void _selectPostTool(_SocialPostTool tool) {
    HapticFeedback.selectionClick();
    setState(() {
      _format = SocialCreateFormatV2.post;
      _postTool = _postTool == tool ? _SocialPostTool.none : tool;
      if (_postTool != _SocialPostTool.image) _media.clear();
    });
    if (_postTool == _SocialPostTool.image) {
      _choosePostImage();
    } else {
      _bodyFocus.requestFocus();
    }
  }

  void _openReelSourcePicker() {
    HapticFeedback.selectionClick();
    setState(() {
      _format = SocialCreateFormatV2.reel;
      _postTool = _SocialPostTool.none;
      _media.clear();
    });
  }

  Future<void> _publish() async {
    if (widget.session.busy) return;
    final type = switch (_format) {
      SocialCreateFormatV2.reel => SocialPublishedContentType.reel,
      SocialCreateFormatV2.carousel => SocialPublishedContentType.carousel,
      SocialCreateFormatV2.post => switch (_postTool) {
        _SocialPostTool.imagePoll => SocialPublishedContentType.imagePoll,
        _SocialPostTool.quickPoll => SocialPublishedContentType.quickPoll,
        _SocialPostTool.quiz => SocialPublishedContentType.quiz,
        _ => SocialPublishedContentType.post,
      },
    };
    final choices = switch (type) {
      SocialPublishedContentType.imagePoll => <SocialPublishedChoice>[
        for (var index = 0; index < 2; index++)
          SocialPublishedChoice(
            label: index == 0 ? _firstChoice.text : _secondChoice.text,
            imagePath: _imagePollMedia[index]?.path,
            imageIsAsset: _imagePollMedia[index]?.isAsset ?? false,
          ),
      ],
      SocialPublishedContentType.quickPoll ||
      SocialPublishedContentType.quiz => <SocialPublishedChoice>[
        SocialPublishedChoice(label: _firstChoice.text),
        SocialPublishedChoice(label: _secondChoice.text),
      ],
      _ => const <SocialPublishedChoice>[],
    };
    final mediaPaths = switch (type) {
      SocialPublishedContentType.imagePoll => const <String>[],
      _ => _media.map((item) => item.path).toList(growable: false),
    };
    final mediaAreAssets =
        _media.isNotEmpty && _media.every((item) => item.isAsset);
    final published = await widget.session.publishSocialContent(
      type: type,
      authorName: widget.authorName,
      authorHandle: widget.authorHandle,
      body: _body.text,
      mediaPaths: mediaPaths,
      mediaAreAssets: mediaAreAssets,
      choices: choices,
      correctChoiceIndex: type == SocialPublishedContentType.quiz
          ? _correctChoice
          : null,
      closesAt:
          type == SocialPublishedContentType.imagePoll ||
              type == SocialPublishedContentType.quickPoll ||
              type == SocialPublishedContentType.quiz
          ? DateTime.now().add(const Duration(days: 7))
          : null,
    );
    if (!mounted) return;
    if (published == null) {
      showSocialV2Message(
        context,
        widget.session.errorMessage ?? 'Your content was not posted.',
      );
      return;
    }
    _clearComposer();
    widget.onPublished(published);
  }

  void _clearComposer() {
    _body.clear();
    _firstChoice.clear();
    _secondChoice.clear();
    setState(() {
      _format = SocialCreateFormatV2.post;
      _media.clear();
      _imagePollMedia
        ..clear()
        ..addAll(<SocialPickedMedia?>[null, null]);
      _postTool = _SocialPostTool.none;
      _correctChoice = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('social-v2-create-workbench'),
      builder: (context, constraints) {
        final preferredDockHeight = switch ((_format, _postTool)) {
          (
            SocialCreateFormatV2.post,
            _SocialPostTool.imagePoll ||
                _SocialPostTool.quickPoll ||
                _SocialPostTool.quiz,
          ) =>
            510.0,
          (SocialCreateFormatV2.post, _SocialPostTool.image) => 420.0,
          (SocialCreateFormatV2.reel, _) => 350.0,
          (SocialCreateFormatV2.carousel, _) => 390.0,
          _ => 295.0,
        };
        final dockHeight = preferredDockHeight
            .clamp(170.0, (constraints.maxHeight - 96).clamp(170.0, 510.0))
            .toDouble();
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
                child: _ContentLibrary(
                  session: widget.session,
                  fillAvailable: true,
                ),
              ),
            ),
            SizedBox(
              height: dockHeight,
              child: DecoratedBox(
                key: const Key('screen04-create-thumb-workbench'),
                decoration: const BoxDecoration(
                  color: Color(0xF8FFFFFF),
                  border: Border(
                    top: BorderSide(color: SocialV2Colors.line),
                    bottom: BorderSide(color: SocialV2Colors.saffron, width: 3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x24000050),
                      blurRadius: 26,
                      offset: Offset(0, -9),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
                        child: _buildWorkbenchCard(),
                      ),
                    ),
                    if (_format == SocialCreateFormatV2.post)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 3),
                        child: _buildPostToolActions(),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 7),
                      child: _buildFormatActions(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkbenchCard() {
    return SocialV2Card(
      key: const Key('screen04-create-workbench'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Create',
                  style: TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _PublicBadge(),
            ],
          ),
          const SizedBox(height: 9),
          _buildPost(),
        ],
      ),
    );
  }

  Widget _buildFormatActions() {
    return Row(
      children: [
        Expanded(
          child: _FormatAction(
            key: const Key('screen04-create-tool-reel'),
            icon: Icons.play_arrow_rounded,
            label: 'Reel',
            selected: _format == SocialCreateFormatV2.reel,
            onTap: _openReelSourcePicker,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _FormatAction(
            key: const Key('screen04-create-tool-carousel'),
            icon: Icons.view_carousel_outlined,
            label: 'Carousel',
            selected: _format == SocialCreateFormatV2.carousel,
            onTap: () => _selectFormat(SocialCreateFormatV2.carousel),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _FormatAction(
            key: const Key('screen04-create-tool-post'),
            icon: Icons.add_rounded,
            label: 'Post',
            selected: _format == SocialCreateFormatV2.post,
            onTap: () => _selectFormat(SocialCreateFormatV2.post),
          ),
        ),
      ],
    );
  }

  Widget _buildPost() {
    final question =
        _format == SocialCreateFormatV2.post &&
        (_postTool == _SocialPostTool.imagePoll ||
            _postTool == _SocialPostTool.quickPoll ||
            _postTool == _SocialPostTool.quiz);
    return Column(
      key: const ValueKey('screen04-create-post-workbench'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: SocialV2Colors.navy,
              foregroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                key: const Key('screen04-create-post-text'),
                controller: _body,
                focusNode: _bodyFocus,
                minLines: 2,
                maxLines: 5,
                maxLength: 1200,
                style: const TextStyle(fontSize: 13, height: 1.3),
                decoration: InputDecoration(
                  hintText: switch (_format) {
                    SocialCreateFormatV2.reel => 'Add a Reel caption',
                    SocialCreateFormatV2.carousel => 'Add a carousel caption',
                    SocialCreateFormatV2.post =>
                      question
                          ? _postTool == _SocialPostTool.quiz
                                ? 'Ask a question'
                                : 'What would you like to ask?'
                          : 'Share publicly',
                  },
                  counterText: '',
                  hintStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        if (_postTool == _SocialPostTool.image && _media.isNotEmpty) ...[
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SocialMediaPreviewV2(
                path: _media.first.path,
                isAsset: _media.first.isAsset,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
        if (_format == SocialCreateFormatV2.reel && _media.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SelectedMediaLine(
            icon: Icons.movie_outlined,
            title: _media.first.name,
            action: 'Change',
            onTap: _openReelSourcePicker,
          ),
        ],
        if (_format == SocialCreateFormatV2.reel && _media.isEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SourceAction(
                  key: const Key('screen04-create-reel-camera'),
                  icon: Icons.videocam_outlined,
                  label: 'Camera',
                  onTap: () => _chooseReel(SocialMediaSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SourceAction(
                  key: const Key('screen04-create-reel-gallery'),
                  icon: Icons.video_library_outlined,
                  label: 'Gallery',
                  onTap: () => _chooseReel(SocialMediaSource.gallery),
                ),
              ),
            ],
          ),
        ],
        if (_format == SocialCreateFormatV2.carousel) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_media.length} / 10 photos',
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('screen04-create-carousel-add'),
                onPressed: _selectingMedia ? null : _chooseCarousel,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_media.isEmpty ? 'Choose photos' : 'Change'),
              ),
            ],
          ),
          if (_media.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _media.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (_, index) => SizedBox(
                  width: 82,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SocialMediaPreviewV2(
                      path: _media[index].path,
                      isAsset: _media[index].isAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
        ],
        if (_format == SocialCreateFormatV2.post &&
            _postTool == _SocialPostTool.imagePoll) ...[
          const SizedBox(height: 9),
          _buildImagePoll(),
        ],
        if (_format == SocialCreateFormatV2.post &&
            (_postTool == _SocialPostTool.quickPoll ||
                _postTool == _SocialPostTool.quiz)) ...[
          const SizedBox(height: 9),
          _buildTextChoices(quiz: _postTool == _SocialPostTool.quiz),
        ],
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showSocialV2Message(
                  context,
                  'Choose when this post should appear.',
                ),
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Post now'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const Key('screen04-create-publish-post'),
                onPressed: widget.session.busy ? null : _publish,
                icon: const Icon(Icons.arrow_upward_rounded),
                label: Text(
                  widget.session.busy
                      ? 'Posting…'
                      : switch (_format) {
                          SocialCreateFormatV2.reel => 'Post Reel',
                          SocialCreateFormatV2.carousel => 'Post Carousel',
                          SocialCreateFormatV2.post => 'Post',
                        },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostToolActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 5.0;
        final width = (constraints.maxWidth - (gap * 3)) / 4;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _ToolAction(
                key: const Key('screen04-create-tool-image'),
                icon: Icons.image_outlined,
                label: 'Image',
                selected: _postTool == _SocialPostTool.image,
                onTap: () => _selectPostTool(_SocialPostTool.image),
              ),
            ),
            SizedBox(
              width: width,
              child: _ToolAction(
                key: const Key('screen04-create-tool-image-poll'),
                icon: Icons.grid_view_rounded,
                label: 'Image Poll',
                selected: _postTool == _SocialPostTool.imagePoll,
                onTap: () => _selectPostTool(_SocialPostTool.imagePoll),
              ),
            ),
            SizedBox(
              width: width,
              child: _ToolAction(
                key: const Key('screen04-create-tool-quick-poll'),
                icon: Icons.poll_outlined,
                label: 'Quick Poll',
                selected: _postTool == _SocialPostTool.quickPoll,
                onTap: () => _selectPostTool(_SocialPostTool.quickPoll),
              ),
            ),
            SizedBox(
              width: width,
              child: _ToolAction(
                key: const Key('screen04-create-tool-quiz'),
                icon: Icons.check_circle_outline_rounded,
                label: 'Quiz',
                selected: _postTool == _SocialPostTool.quiz,
                onTap: () => _selectPostTool(_SocialPostTool.quiz),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePoll() {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SocialV2Colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Image Poll',
            style: TextStyle(
              color: SocialV2Colors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var index = 0; index < 2; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(child: _imagePollChoiceEditor(index)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePollChoiceEditor(int index) {
    final media = _imagePollMedia[index];
    final controller = index == 0 ? _firstChoice : _secondChoice;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: OutlinedButton(
            key: Key('screen04-create-image-poll-media-$index'),
            onPressed: () => _chooseImagePollMedia(index),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: media == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined),
                      SizedBox(height: 4),
                      Text('Add image'),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SocialMediaPreviewV2(
                      path: media.path,
                      isAsset: media.isAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: Key('screen04-create-image-poll-choice-$index'),
          controller: controller,
          style: const TextStyle(fontSize: 12.5, height: 1.25),
          decoration: InputDecoration(
            hintText: 'Choice ${index + 1}',
            hintStyle: const TextStyle(fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTextChoices({required bool quiz}) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SocialV2Colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            quiz ? 'Quiz' : 'Quick Poll',
            style: const TextStyle(
              color: SocialV2Colors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          RadioGroup<int>(
            groupValue: _correctChoice,
            onChanged: (value) {
              if (quiz) setState(() => _correctChoice = value ?? 0);
            },
            child: Column(
              children: [
                for (var index = 0; index < 2; index++) ...[
                  Row(
                    children: [
                      if (quiz) Radio<int>(value: index),
                      Expanded(
                        child: TextField(
                          key: Key(
                            'screen04-create-${quiz ? 'quiz' : 'quick-poll'}-choice-$index',
                          ),
                          controller: index == 0 ? _firstChoice : _secondChoice,
                          style: const TextStyle(fontSize: 12.5, height: 1.25),
                          decoration: InputDecoration(
                            hintText: quiz
                                ? 'Answer ${index + 1}'
                                : 'Choice ${index + 1}',
                            hintStyle: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (index == 0) const SizedBox(height: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quiz ? 'Select the correct answer' : 'Closes in 7 days',
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

class _PublicBadge extends StatelessWidget {
  const _PublicBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SocialV2Colors.green,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'Public',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SourceAction extends StatelessWidget {
  const _SourceAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 64)),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _FormatAction extends StatelessWidget {
  const _FormatAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? SocialV2Colors.navy : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: selected ? SocialV2Colors.navy : SocialV2Colors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected ? Colors.white : SocialV2Colors.navy,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : SocialV2Colors.navy,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMediaLine extends StatelessWidget {
  const _SelectedMediaLine({
    required this.icon,
    required this.title,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SocialV2Colors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: SocialV2Colors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SocialV2Colors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}

class _ToolAction extends StatelessWidget {
  const _ToolAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? const Color(0x10000080) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: selected ? SocialV2Colors.navy : SocialV2Colors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: SocialV2Colors.navy),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SocialV2Colors.navy,
                      fontSize: 9.5,
                      height: 1.02,
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

class _ContentLibrary extends StatefulWidget {
  const _ContentLibrary({required this.session, this.fillAvailable = false});

  final SharedSession session;
  final bool fillAvailable;

  @override
  State<_ContentLibrary> createState() => _ContentLibraryState();
}

class _ContentLibraryState extends State<_ContentLibrary> {
  String _selected = 'Drafts';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (_, _) {
        final items = _selected == 'Published'
            ? widget.session.socialPublishedItems.take(6).toList()
            : const <SocialPublishedItem>[];
        final emptyState = Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: SocialV2Colors.canvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SocialV2Colors.line),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.bookmark_border_rounded,
                color: SocialV2Colors.navy,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (_selected) {
                        'Scheduled' => 'Nothing scheduled',
                        'Published' => 'No published content yet',
                        'Archived' => 'No archived content',
                        _ => 'No drafts yet',
                      },
                      style: const TextStyle(
                        color: SocialV2Colors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      switch (_selected) {
                        'Scheduled' => 'Schedule a post for a future time.',
                        'Published' => 'Posts you publish will appear here.',
                        'Archived' =>
                          'Content you archive will remain available here.',
                        _ => 'Your unfinished content will stay here.',
                      },
                      style: const TextStyle(
                        color: SocialV2Colors.muted,
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        final tabs = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final label in const [
                'Drafts',
                'Scheduled',
                'Published',
                'Archived',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: TextButton(
                    key: Key('screen04-create-library-${label.toLowerCase()}'),
                    onPressed: () => setState(() => _selected = label),
                    style: TextButton.styleFrom(
                      foregroundColor: _selected == label
                          ? SocialV2Colors.navy
                          : SocialV2Colors.muted,
                      minimumSize: const Size(76, 44),
                      side: BorderSide(
                        color: _selected == label
                            ? SocialV2Colors.saffron
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );

        Widget itemTile(SocialPublishedItem item) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: SocialV2Colors.navy,
            foregroundColor: Colors.white,
            child: Icon(_contentIcon(item.type), size: 18),
          ),
          title: Text(
            item.body.isEmpty ? _contentLabel(item.type) : item.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SocialV2Colors.ink,
              fontSize: 12,
              height: 1.18,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${_contentLabel(item.type)} · Published',
            style: const TextStyle(
              color: SocialV2Colors.muted,
              fontSize: 10.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
        );

        return SocialV2Card(
          key: const Key('screen04-create-content-library'),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: widget.fillAvailable
              ? CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: tabs),
                    const SliverToBoxAdapter(child: SizedBox(height: 7)),
                    if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: emptyState,
                      )
                    else
                      SliverList.builder(
                        itemCount: items.length,
                        itemBuilder: (_, index) => itemTile(items[index]),
                      ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tabs,
                    const SizedBox(height: 7),
                    if (items.isEmpty)
                      emptyState
                    else
                      for (final item in items) itemTile(item),
                  ],
                ),
        );
      },
    );
  }
}

String _contentLabel(SocialPublishedContentType type) => switch (type) {
  SocialPublishedContentType.reel => 'Reel',
  SocialPublishedContentType.carousel => 'Carousel',
  SocialPublishedContentType.post => 'Post',
  SocialPublishedContentType.imagePoll => 'Image Poll',
  SocialPublishedContentType.quickPoll => 'Quick Poll',
  SocialPublishedContentType.quiz => 'Quiz',
};

IconData _contentIcon(SocialPublishedContentType type) => switch (type) {
  SocialPublishedContentType.reel => Icons.play_arrow_rounded,
  SocialPublishedContentType.carousel => Icons.view_carousel_outlined,
  SocialPublishedContentType.post => Icons.article_outlined,
  SocialPublishedContentType.imagePoll => Icons.grid_view_rounded,
  SocialPublishedContentType.quickPoll => Icons.poll_outlined,
  SocialPublishedContentType.quiz => Icons.check_circle_outline_rounded,
};
