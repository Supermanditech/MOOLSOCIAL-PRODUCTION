import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/shared/shared_models.dart';
import '../../features/shared/social_create_draft_repository.dart';
import '../../features/shared/shared_session.dart';
import '../../features/shared/social_media_picker.dart';
import 'social_v2_design.dart';
import 'social_v2_public_content.dart';

enum SocialCreateFormatV2 { reel, carousel, post }

enum SocialCreateIntentV2 { text, image, carousel, imagePoll, quickPoll, quiz }

enum _SocialPostTool { none, image, imagePoll, quickPoll, quiz }

class SocialCreateDraftV2 {
  bool _initialized = false;
  SocialCreateFormatV2 _format = SocialCreateFormatV2.post;
  _SocialPostTool _postTool = _SocialPostTool.none;
  String _body = '';
  final List<String> _choices = List<String>.filled(4, '');
  final List<SocialPickedMedia> _media = <SocialPickedMedia>[];
  final List<SocialPickedMedia?> _imagePollMedia = <SocialPickedMedia?>[
    null,
    null,
    null,
    null,
  ];
  int _correctChoice = 0;
  SocialQuotedPost? _quotedPost;
  int _revision = 1;
  VoidCallback? _onChanged;

  SocialQuotedPost? get quotedPost => _quotedPost;

  String? get quotedPostId => _quotedPost?.id;

  List<SocialPickedMedia> get media => List.unmodifiable(_media);
  List<SocialPickedMedia?> get imagePollMedia =>
      List.unmodifiable(_imagePollMedia);
  int get revision => _revision;
  String get body => _body;
  List<String> get choices => List.unmodifiable(_choices);
  String get formatName => _format.name;
  String get toolName => _postTool.name;
  int get correctChoice => _correctChoice;

  void setChangeListener(VoidCallback? listener) => _onChanged = listener;

  SocialCreateDraftSnapshot toPersistenceSnapshot({
    required SocialCreateDraftStateCache cache,
    required List<SocialCreateDraftMediaReference> media,
    required List<SocialCreateDraftMediaReference?> imagePollMedia,
  }) => cache.createSnapshot(
    initialized: _initialized,
    format: SocialCreateDraftFormat.values.byName(_format.name),
    tool: SocialCreateDraftTool.values.byName(_postTool.name),
    body: _body,
    choices: _choices,
    media: media,
    imagePollMedia: imagePollMedia,
    correctChoice: _correctChoice,
    quote: _quotedPost == null
        ? null
        : SocialCreateDraftQuote(
            id: _quotedPost!.id,
            authorName: _quotedPost!.authorName,
            authorHandle: _quotedPost!.authorHandle,
            body: _quotedPost!.body,
            mediaUrl: _httpsUriOrNull(_quotedPost!.mediaPath),
          ),
    revision: _revision,
  );

  void applyPersistenceSnapshot(
    SocialCreateDraftSnapshot snapshot, {
    required List<SocialPickedMedia> media,
    required List<SocialPickedMedia?> imagePollMedia,
  }) {
    _initialized = snapshot.initialized;
    _format = SocialCreateFormatV2.values.byName(snapshot.format.name);
    _postTool = _SocialPostTool.values.byName(snapshot.tool.name);
    _body = snapshot.body;
    _choices.setAll(0, snapshot.choices);
    _media
      ..clear()
      ..addAll(media);
    _imagePollMedia
      ..clear()
      ..addAll(imagePollMedia);
    _correctChoice = snapshot.correctChoice;
    final quote = snapshot.quote;
    _quotedPost = quote == null
        ? null
        : SocialQuotedPost(
            id: quote.id,
            authorName: quote.authorName,
            authorHandle: quote.authorHandle,
            body: quote.body,
            mediaPath: quote.mediaUrl?.toString(),
          );
    _revision = snapshot.revision;
  }

  void _markChanged() {
    _revision += 1;
    _onChanged?.call();
  }

  void prepareQuotedPost(SocialPublishedItem item) {
    _initialized = true;
    _format = SocialCreateFormatV2.post;
    _postTool = _SocialPostTool.none;
    _quotedPost = SocialQuotedPost(
      id: item.id,
      authorName: item.authorName,
      authorHandle: item.authorHandle,
      body: item.body,
      mediaPath: item.mediaPaths.firstOrNull,
    );
    _markChanged();
  }

  void _clear() {
    _initialized = true;
    _format = SocialCreateFormatV2.post;
    _postTool = _SocialPostTool.none;
    _body = '';
    _choices.fillRange(0, _choices.length, '');
    _media.clear();
    _imagePollMedia.fillRange(0, _imagePollMedia.length, null);
    _correctChoice = 0;
    _quotedPost = null;
    _markChanged();
  }

  static Uri? _httpsUriOrNull(String? raw) {
    final uri = raw == null ? null : Uri.tryParse(raw);
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }
}

class SocialCreateWorkbenchV2 extends StatefulWidget {
  const SocialCreateWorkbenchV2({
    required this.session,
    required this.mediaPicker,
    required this.authorName,
    required this.authorHandle,
    required this.onPublished,
    this.draft,
    this.initialFormat = SocialCreateFormatV2.post,
    this.initialIntent,
    this.allowReel = true,
    this.onCreateYouTubeShort,
    this.onClose,
    this.onBeforeClose,
    this.onBeforeDraftClear,
    this.recoverInterruptedMedia = true,
    this.disableLocalMediaPreviewForTesting = false,
    super.key,
  });

  final SharedSession session;
  final SocialMediaPicker mediaPicker;
  final String authorName;
  final String authorHandle;
  final ValueChanged<SocialPublishedItem> onPublished;
  final SocialCreateDraftV2? draft;
  final SocialCreateFormatV2 initialFormat;
  final SocialCreateIntentV2? initialIntent;
  final bool allowReel;
  final VoidCallback? onCreateYouTubeShort;
  final VoidCallback? onClose;
  final Future<bool> Function()? onBeforeClose;
  final Future<void> Function()? onBeforeDraftClear;
  final bool recoverInterruptedMedia;
  @visibleForTesting
  final bool disableLocalMediaPreviewForTesting;

  @override
  State<SocialCreateWorkbenchV2> createState() =>
      _SocialCreateWorkbenchV2State();
}

class _SocialCreateWorkbenchV2State extends State<SocialCreateWorkbenchV2> {
  late SocialCreateFormatV2 _format;
  late _SocialPostTool _postTool;
  late final SocialCreateDraftV2 _draft;
  final TextEditingController _body = TextEditingController();
  final List<TextEditingController> _choiceControllers =
      List<TextEditingController>.generate(4, (_) => TextEditingController());
  final FocusNode _bodyFocus = FocusNode();
  late final List<SocialPickedMedia> _media;
  late final List<SocialPickedMedia?> _imagePollMedia;
  int _correctChoice = 0;
  bool _selectingMedia = false;
  bool _draftOperationLocked = false;
  int _mediaSelectionRequest = 0;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? SocialCreateDraftV2();
    final freshDraft = !_draft._initialized;
    final intent = widget.initialIntent;
    if (freshDraft) {
      _draft._format = intent == SocialCreateIntentV2.carousel
          ? SocialCreateFormatV2.carousel
          : !widget.allowReel &&
                widget.initialFormat == SocialCreateFormatV2.reel
          ? SocialCreateFormatV2.post
          : widget.initialFormat;
      _draft._postTool = switch (intent) {
        SocialCreateIntentV2.image => _SocialPostTool.image,
        SocialCreateIntentV2.imagePoll => _SocialPostTool.imagePoll,
        SocialCreateIntentV2.quickPoll => _SocialPostTool.quickPoll,
        SocialCreateIntentV2.quiz => _SocialPostTool.quiz,
        _ => _SocialPostTool.none,
      };
      _draft._initialized = true;
    }
    _format = _draft._format;
    _postTool = _draft._postTool;
    _media = _draft._media;
    _imagePollMedia = _draft._imagePollMedia;
    _correctChoice = _draft._correctChoice;
    _body.text = _draft._body;
    for (var index = 0; index < _choiceControllers.length; index++) {
      _choiceControllers[index].text = _draft._choices[index];
      _choiceControllers[index].addListener(_persistTextDraft);
    }
    _body.addListener(_persistTextDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.recoverInterruptedMedia) {
        await _recoverInterruptedSelection();
      }
      if (!mounted || widget.initialIntent != intent) return;
      if (freshDraft && intent == SocialCreateIntentV2.image) {
        await _choosePostImage();
      } else if (freshDraft && intent == SocialCreateIntentV2.carousel) {
        await _chooseCarousel();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SocialCreateWorkbenchV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    final intent = widget.initialIntent;
    if (intent == null || oldWidget.initialIntent == intent) return;
    final selectionWasPending = _selectingMedia;
    setState(() {
      _invalidateMediaSelection();
      _format = intent == SocialCreateIntentV2.carousel
          ? SocialCreateFormatV2.carousel
          : SocialCreateFormatV2.post;
      _postTool = switch (intent) {
        SocialCreateIntentV2.image => _SocialPostTool.image,
        SocialCreateIntentV2.imagePoll => _SocialPostTool.imagePoll,
        SocialCreateIntentV2.quickPoll => _SocialPostTool.quickPoll,
        SocialCreateIntentV2.quiz => _SocialPostTool.quiz,
        _ => _SocialPostTool.none,
      };
      _persistDraftState();
    });
    if (!selectionWasPending &&
        intent == SocialCreateIntentV2.image &&
        _media.isEmpty) {
      _choosePostImage();
    } else if (!selectionWasPending &&
        intent == SocialCreateIntentV2.carousel &&
        _media.length < 2) {
      _chooseCarousel();
    }
  }

  @override
  void dispose() {
    _body.removeListener(_persistTextDraft);
    _body.dispose();
    for (final controller in _choiceControllers) {
      controller.removeListener(_persistTextDraft);
      controller.dispose();
    }
    _bodyFocus.dispose();
    super.dispose();
  }

  void _persistTextDraft() {
    _draft._body = _body.text;
    for (var index = 0; index < _choiceControllers.length; index++) {
      _draft._choices[index] = _choiceControllers[index].text;
    }
    _draft._markChanged();
  }

  void _persistDraftState() {
    _draft
      .._initialized = true
      .._format = _format
      .._postTool = _postTool
      .._correctChoice = _correctChoice;
    _persistTextDraft();
  }

  void _invalidateMediaSelection() {
    _mediaSelectionRequest += 1;
    _selectingMedia = false;
  }

  bool _mediaSelectionIsCurrent(
    int request, {
    required SocialCreateFormatV2 format,
    _SocialPostTool? postTool,
  }) {
    return mounted &&
        request == _mediaSelectionRequest &&
        _format == format &&
        (postTool == null || _postTool == postTool);
  }

  Future<void> _recoverInterruptedSelection() async {
    final request = ++_mediaSelectionRequest;
    late final List<SocialPickedMedia> recovered;
    try {
      recovered = await widget.mediaPicker.recoverInterruptedSelection();
    } on Object {
      if (mounted && request == _mediaSelectionRequest) {
        showSocialV2Message(
          context,
          'Your previous media selection could not be restored. Your draft is still here.',
        );
      }
      return;
    }
    if (!mounted || request != _mediaSelectionRequest || recovered.isEmpty) {
      return;
    }
    setState(() {
      if (recovered.first.kind == SocialMediaKind.video) {
        if (!widget.allowReel) return;
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
      _persistDraftState();
    });
  }

  Future<void> _selectFormat(SocialCreateFormatV2 format) async {
    if (format == SocialCreateFormatV2.reel && !widget.allowReel) return;
    HapticFeedback.selectionClick();
    setState(() {
      _invalidateMediaSelection();
      _format = format;
      if (format != SocialCreateFormatV2.post) _postTool = _SocialPostTool.none;
      _persistDraftState();
    });
    if (format == SocialCreateFormatV2.post) {
      _bodyFocus.requestFocus();
    } else if (format == SocialCreateFormatV2.carousel && _media.length < 2) {
      await _chooseCarousel();
    }
  }

  Future<void> _chooseReel(SocialMediaSource source) async {
    if (_selectingMedia) return;
    final request = ++_mediaSelectionRequest;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickReel(source);
      if (!_mediaSelectionIsCurrent(
            request,
            format: SocialCreateFormatV2.reel,
          ) ||
          selected == null) {
        return;
      }
      setState(() {
        _media
          ..clear()
          ..add(selected);
        _persistDraftState();
      });
    } on Object {
      if (!mounted) return;
      if (_mediaSelectionIsCurrent(
        request,
        format: SocialCreateFormatV2.reel,
      )) {
        showSocialV2Message(
          context,
          'Videos could not be opened. Your draft is still here.',
        );
      }
    } finally {
      if (mounted && request == _mediaSelectionRequest) {
        setState(() => _selectingMedia = false);
      }
    }
  }

  Future<void> _chooseCarousel() async {
    if (_selectingMedia) return;
    final request = ++_mediaSelectionRequest;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickCarousel(limit: 10);
      if (!_mediaSelectionIsCurrent(
            request,
            format: SocialCreateFormatV2.carousel,
          ) ||
          selected.isEmpty) {
        return;
      }
      setState(() {
        _media
          ..clear()
          ..addAll(selected.take(10));
        _persistDraftState();
      });
    } on Object {
      if (!mounted) return;
      if (_mediaSelectionIsCurrent(
        request,
        format: SocialCreateFormatV2.carousel,
      )) {
        showSocialV2Message(
          context,
          'Photos could not be opened. Your draft is still here.',
        );
      }
    } finally {
      if (mounted && request == _mediaSelectionRequest) {
        setState(() => _selectingMedia = false);
      }
    }
  }

  Future<void> _choosePostImage() async {
    if (_selectingMedia) return;
    final request = ++_mediaSelectionRequest;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickImage(
        SocialMediaSource.gallery,
      );
      if (!_mediaSelectionIsCurrent(
            request,
            format: SocialCreateFormatV2.post,
            postTool: _SocialPostTool.image,
          ) ||
          selected == null) {
        return;
      }
      setState(() {
        _media
          ..clear()
          ..add(selected);
        _persistDraftState();
      });
    } on Object {
      if (!mounted) return;
      if (_mediaSelectionIsCurrent(
        request,
        format: SocialCreateFormatV2.post,
        postTool: _SocialPostTool.image,
      )) {
        showSocialV2Message(
          context,
          'Photos could not be opened. Your draft is still here.',
        );
      }
    } finally {
      if (mounted && request == _mediaSelectionRequest) {
        setState(() => _selectingMedia = false);
      }
    }
  }

  Future<void> _chooseImagePollMedia(int index) async {
    if (_selectingMedia) return;
    final request = ++_mediaSelectionRequest;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickImage(
        SocialMediaSource.gallery,
      );
      if (!_mediaSelectionIsCurrent(
            request,
            format: SocialCreateFormatV2.post,
            postTool: _SocialPostTool.imagePoll,
          ) ||
          selected == null) {
        return;
      }
      setState(() {
        _imagePollMedia[index] = selected;
        _persistDraftState();
      });
    } on Object {
      if (!mounted) return;
      if (_mediaSelectionIsCurrent(
        request,
        format: SocialCreateFormatV2.post,
        postTool: _SocialPostTool.imagePoll,
      )) {
        showSocialV2Message(
          context,
          'Photos could not be opened. Your draft is still here.',
        );
      }
    } finally {
      if (mounted && request == _mediaSelectionRequest) {
        setState(() => _selectingMedia = false);
      }
    }
  }

  void _selectPostTool(_SocialPostTool tool) {
    HapticFeedback.selectionClick();
    setState(() {
      _invalidateMediaSelection();
      _format = SocialCreateFormatV2.post;
      _postTool = _postTool == tool ? _SocialPostTool.none : tool;
      if (_postTool != _SocialPostTool.image) _media.clear();
      _persistDraftState();
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
      _invalidateMediaSelection();
      _format = SocialCreateFormatV2.reel;
      _postTool = _SocialPostTool.none;
      _media.clear();
      _persistDraftState();
    });
  }

  Future<void> _publish() async {
    if (widget.session.busy || _selectingMedia) return;
    if (_draft.quotedPost != null && _body.text.trim().isEmpty) {
      showSocialV2Message(
        context,
        'Add your thoughts before sharing this post.',
      );
      _bodyFocus.requestFocus();
      return;
    }
    final session = widget.session;
    final submittedDraftFingerprint = _draftFingerprint();
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
        for (var index = 0; index < _choiceControllers.length; index++)
          SocialPublishedChoice(
            label: _choiceControllers[index].text,
            imagePath: _imagePollMedia[index]?.path,
            imageIsAsset: _imagePollMedia[index]?.isAsset ?? false,
          ),
      ],
      SocialPublishedContentType.quickPoll ||
      SocialPublishedContentType.quiz => <SocialPublishedChoice>[
        for (final controller in _choiceControllers)
          SocialPublishedChoice(label: controller.text),
      ],
      _ => const <SocialPublishedChoice>[],
    };
    final publishedMedia = switch (type) {
      SocialPublishedContentType.reel ||
      SocialPublishedContentType.carousel => _media,
      SocialPublishedContentType.post when _postTool == _SocialPostTool.image =>
        _media,
      _ => const <SocialPickedMedia>[],
    };
    final mediaPaths = publishedMedia
        .map((item) => item.path)
        .toList(growable: false);
    final mediaAreAssets =
        publishedMedia.isNotEmpty &&
        publishedMedia.every((item) => item.isAsset);
    final published = await session.publishSocialContent(
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
      quotedPostId: _draft.quotedPostId,
    );
    if (!mounted || !identical(session, widget.session)) return;
    if (published == null) {
      showSocialV2Message(
        context,
        session.errorMessage ?? 'Your content was not posted.',
      );
      return;
    }
    if (_draftFingerprint() == submittedDraftFingerprint) {
      _invalidateMediaSelection();
      setState(() => _draftOperationLocked = true);
      try {
        await widget.onBeforeDraftClear?.call();
      } on Object {
        if (!mounted) return;
        setState(() => _draftOperationLocked = false);
        showSocialV2Message(
          context,
          'Published, but local draft cleanup needs another try.',
        );
        widget.onPublished(published);
        return;
      }
      if (!mounted) return;
      _clearComposer();
    } else {
      _persistDraftState();
    }
    widget.onPublished(published);
  }

  String _draftFingerprint() {
    return <Object?>[
      _format.name,
      _postTool.name,
      _body.text,
      for (final item in _media)
        '${item.path}|${item.kind.name}|${item.isAsset}',
      for (final item in _imagePollMedia)
        item == null ? null : '${item.path}|${item.kind.name}|${item.isAsset}',
      for (final controller in _choiceControllers) controller.text,
      _correctChoice,
      _draft.quotedPostId,
    ].join('\u001e');
  }

  void _clearComposer() {
    _invalidateMediaSelection();
    _draft._clear();
    _body.clear();
    for (final controller in _choiceControllers) {
      controller.clear();
    }
    setState(() {
      _draftOperationLocked = false;
      _format = SocialCreateFormatV2.post;
      _media.clear();
      _imagePollMedia
        ..clear()
        ..addAll(<SocialPickedMedia?>[null, null, null, null]);
      _postTool = _SocialPostTool.none;
      _correctChoice = 0;
      _persistDraftState();
    });
  }

  bool get _hasDraftContent =>
      _body.text.trim().isNotEmpty ||
      _choiceControllers.any(
        (controller) => controller.text.trim().isNotEmpty,
      ) ||
      _media.isNotEmpty ||
      _imagePollMedia.any((item) => item != null) ||
      _draft.quotedPost != null ||
      _format != SocialCreateFormatV2.post ||
      _postTool != _SocialPostTool.none;

  Future<void> _confirmDiscard() async {
    if (!_hasDraftContent) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('screen04-create-discard-confirmation'),
        title: const Text('Discard this draft?'),
        content: const Text(
          'Your unpublished changes and staged media will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            key: const Key('screen04-create-discard-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    _invalidateMediaSelection();
    setState(() => _draftOperationLocked = true);
    try {
      await widget.onBeforeDraftClear?.call();
    } on Object {
      if (mounted) {
        setState(() => _draftOperationLocked = false);
        showSocialV2Message(context, 'Draft cleanup failed. Please try again.');
      }
      return;
    }
    _clearComposer();
    widget.onClose?.call();
  }

  Future<void> _requestClose() async {
    if (_draftOperationLocked) return;
    setState(() => _draftOperationLocked = true);
    var confirmed = true;
    try {
      confirmed = await widget.onBeforeClose?.call() ?? true;
    } on Object {
      confirmed = false;
    }
    if (!mounted) return;
    if (!confirmed) {
      setState(() => _draftOperationLocked = false);
      showSocialV2Message(context, 'Draft save failed. Please try again.');
      return;
    }
    widget.onClose?.call();
    if (mounted) setState(() => _draftOperationLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('social-v2-create-workbench'),
      decoration: const BoxDecoration(color: SocialV2Colors.canvas),
      child: IgnorePointer(
        ignoring: _draftOperationLocked,
        child: Column(
          children: [
            Material(
              key: const Key('screen04-create-composer-header'),
              color: Colors.white,
              elevation: 1,
              shadowColor: const Color(0x22000050),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 58,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        if (widget.onClose != null)
                          IconButton(
                            key: const Key('screen04-create-close'),
                            tooltip: 'Close composer',
                            onPressed: _requestClose,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        Expanded(
                          child: Text(
                            _composerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SocialV2Colors.navy,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('screen04-create-discard'),
                          tooltip: 'Discard draft',
                          onPressed: _confirmDiscard,
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                        SizedBox(
                          width: 96,
                          height: 44,
                          child: FilledButton.icon(
                            key: const Key('screen04-create-publish-post'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(96, 44),
                              maximumSize: const Size(96, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: widget.session.busy || _selectingMedia
                                ? null
                                : _publish,
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                            ),
                            label: Text(
                              widget.session.busy ? 'Posting…' : 'Post',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('screen04-create-scrollable-composer'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: _buildWorkbenchCard(),
              ),
            ),
            Material(
              key: const Key('screen04-create-thumb-workbench'),
              color: Colors.white,
              elevation: 12,
              shadowColor: const Color(0x26000050),
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_format == SocialCreateFormatV2.post) ...[
                        _buildPostToolActions(),
                        const SizedBox(height: 5),
                      ],
                      _buildFormatActions(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _composerTitle => switch ((_format, _postTool)) {
    (SocialCreateFormatV2.carousel, _) => 'New carousel',
    (SocialCreateFormatV2.reel, _) => 'New Reel',
    (SocialCreateFormatV2.post, _SocialPostTool.image) => 'New image post',
    (SocialCreateFormatV2.post, _SocialPostTool.imagePoll) => 'New image poll',
    (SocialCreateFormatV2.post, _SocialPostTool.quickPoll) => 'New quick poll',
    (SocialCreateFormatV2.post, _SocialPostTool.quiz) => 'New quiz',
    _ => 'New text post',
  };

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoolSocial post',
                      style: TextStyle(
                        color: SocialV2Colors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Share text, photos, polls or a quiz in Feed',
                      style: TextStyle(
                        color: SocialV2Colors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _PublicBadge(),
            ],
          ),
          const SizedBox(height: 9),
          if (_draft.quotedPost case final quotedPost?) ...[
            SocialQuotedPostPreviewV2(
              key: const Key('social-create-quoted-post'),
              quotedPost: quotedPost,
            ),
            const SizedBox(height: 9),
          ],
          _buildPost(),
        ],
      ),
    );
  }

  Widget _buildFormatActions() {
    return Row(
      children: [
        if (widget.onCreateYouTubeShort != null) ...[
          Expanded(
            child: _FormatAction(
              key: const Key('screen04-create-youtube-short'),
              icon: Icons.play_circle_outline_rounded,
              label: 'YouTube Short',
              selected: false,
              onTap: widget.onCreateYouTubeShort!,
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (widget.allowReel) ...[
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
        ],
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
          child: KeyedSubtree(
            key: const Key('social-create-moolsocial-post'),
            child: _FormatAction(
              key: const Key('screen04-create-tool-post'),
              icon: Icons.edit_note_rounded,
              label: 'Text',
              selected: _format == SocialCreateFormatV2.post,
              onTap: () => _selectFormat(SocialCreateFormatV2.post),
            ),
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
              child:
                  widget.disableLocalMediaPreviewForTesting &&
                      !_media.first.isAsset
                  ? const ColoredBox(
                      key: Key('screen04-create-local-media-test-preview'),
                      color: SocialV2Colors.canvas,
                    )
                  : SocialMediaPreviewV2(
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              childAspectRatio: .72,
            ),
            itemCount: _choiceControllers.length,
            itemBuilder: (_, index) => _imagePollChoiceEditor(index),
          ),
        ],
      ),
    );
  }

  Widget _imagePollChoiceEditor(int index) {
    final media = _imagePollMedia[index];
    final controller = _choiceControllers[index];
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
              if (quiz) {
                setState(() {
                  _correctChoice = value ?? 0;
                  _persistDraftState();
                });
              }
            },
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < _choiceControllers.length;
                  index++
                ) ...[
                  Row(
                    children: [
                      if (quiz) Radio<int>(value: index),
                      Expanded(
                        child: TextField(
                          key: Key(
                            'screen04-create-${quiz ? 'quiz' : 'quick-poll'}-choice-$index',
                          ),
                          controller: _choiceControllers[index],
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
                  if (index < _choiceControllers.length - 1)
                    const SizedBox(height: 7),
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final additionalHeight = textScale > 1 ? (textScale - 1) * 14.0 : 0.0;
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
            height: 56.0 + additionalHeight,
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
