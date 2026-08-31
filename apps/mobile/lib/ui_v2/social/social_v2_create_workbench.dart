import 'dart:async';

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
  bool get hasUserContent =>
      _body.trim().isNotEmpty ||
      _choices.any((choice) => choice.trim().isNotEmpty) ||
      _media.isNotEmpty ||
      _imagePollMedia.any((item) => item != null) ||
      _quotedPost != null;
  bool get hasMeaningfulContent =>
      hasUserContent ||
      _format != SocialCreateFormatV2.post ||
      _postTool != _SocialPostTool.none;

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

  bool prepareFreshIntent(SocialCreateIntentV2 intent) {
    if (hasUserContent) return false;
    _initialized = true;
    _applyIntent(intent);
    _body = '';
    _choices.fillRange(0, _choices.length, '');
    _media.clear();
    _imagePollMedia.fillRange(0, _imagePollMedia.length, null);
    _correctChoice = 0;
    _quotedPost = null;
    _markChanged();
    return true;
  }

  void retargetIntent(SocialCreateIntentV2 intent) {
    _initialized = true;
    _applyIntent(intent);
    _markChanged();
  }

  void _applyIntent(SocialCreateIntentV2 intent) {
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
    this.externalOperationLocked = false,
    this.previewOnly = false,
    this.onPreviewSignIn,
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
  final bool externalOperationLocked;
  final bool previewOnly;
  final VoidCallback? onPreviewSignIn;

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
    if (!oldWidget.externalOperationLocked && widget.externalOperationLocked) {
      _invalidateMediaSelection();
      _bodyFocus.unfocus();
    }
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

  void _insertComposerText(String value) {
    final current = _body.value;
    final selection = current.selection.isValid
        ? current.selection
        : TextSelection.collapsed(offset: current.text.length);
    final replacement = current.text.replaceRange(
      selection.start,
      selection.end,
      value,
    );
    _body.value = TextEditingValue(
      text: replacement,
      selection: TextSelection.collapsed(
        offset: selection.start + value.length,
      ),
    );
    _bodyFocus.requestFocus();
  }

  Future<void> _openEmojiPalette() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a feeling',
                style: TextStyle(
                  color: SocialV2Colors.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose one or use your keyboard for every emoji.',
                style: TextStyle(color: SocialV2Colors.muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in const [
                    '✨',
                    '❤️',
                    '👏',
                    '😊',
                    '🎉',
                    '💡',
                    '🌱',
                    '🙏',
                  ])
                    Semantics(
                      button: true,
                      label: 'Insert $value',
                      child: InkWell(
                        key: Key('screen04-create-emoji-$value'),
                        onTap: () => Navigator.pop(sheetContext, value),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F1FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || emoji == null) return;
    _insertComposerText(emoji);
  }

  void _showGifAvailability() {
    showSocialV2Message(
      context,
      'GIF search will appear here when the approved media service is connected. Your draft is unchanged.',
    );
  }

  Future<void> _openPreview() async {
    if (!_hasDraftContent) {
      showSocialV2Message(
        context,
        'Add a thought, photo, poll or quiz before opening Preview.',
      );
      _bodyFocus.requestFocus();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: .86,
          child: _CreateFeedPreview(
            authorName: widget.authorName,
            authorHandle: widget.authorHandle,
            body: _body.text,
            format: _format,
            tool: _postTool,
            media: _media,
            imagePollMedia: _imagePollMedia,
            choices: [
              for (final controller in _choiceControllers) controller.text,
            ],
            onClose: () => Navigator.pop(sheetContext),
          ),
        ),
      ),
    );
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
    if (widget.previewOnly) {
      widget.onPreviewSignIn?.call();
      return;
    }
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
        ignoring: _draftOperationLocked || widget.externalOperationLocked,
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
                          width: widget.previewOnly ? 126 : 96,
                          height: 44,
                          child: FilledButton.icon(
                            key: const Key('screen04-create-publish-post'),
                            style: FilledButton.styleFrom(
                              minimumSize: Size(
                                widget.previewOnly ? 126 : 96,
                                44,
                              ),
                              maximumSize: Size(
                                widget.previewOnly ? 126 : 96,
                                44,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed:
                                !widget.previewOnly &&
                                    (widget.session.busy || _selectingMedia)
                                ? null
                                : _publish,
                            icon: Icon(
                              widget.previewOnly
                                  ? Icons.login_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 18,
                            ),
                            label: Text(
                              widget.previewOnly
                                  ? 'Sign in to post'
                                  : widget.session.busy
                                  ? 'Posting…'
                                  : 'Post',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.previewOnly)
              const Material(
                key: Key('screen04-create-preview-notice'),
                color: Color(0xFFFFF4DE),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: Color(0xFF8A4B00),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Create preview · Nothing can be published until you sign in.',
                          style: TextStyle(
                            color: Color(0xFF6A3A00),
                            fontSize: 11.5,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const Key('screen04-create-workbench'),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF7F4FF), Color(0xFFFFFBF4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDCD5FF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000050),
              blurRadius: 16,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), SocialV2Colors.navy],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create canvas',
                        style: TextStyle(
                          color: SocialV2Colors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _canvasGuidance,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SocialV2Colors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const _PublicBadge(),
              ],
            ),
            const SizedBox(height: 10),
            _CreateCanvasStageRail(onPreview: _openPreview),
            const SizedBox(height: 10),
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
      ),
    );
  }

  String get _canvasGuidance => switch ((_format, _postTool)) {
    (SocialCreateFormatV2.carousel, _) =>
      'Arrange a swipe story, then add the thread that connects it.',
    (SocialCreateFormatV2.reel, _) =>
      'Shape the opening moment before you share the full story.',
    (SocialCreateFormatV2.post, _SocialPostTool.image) =>
      'Let one strong image lead and give people useful context.',
    (SocialCreateFormatV2.post, _SocialPostTool.imagePoll) =>
      'Make each visual choice clear before inviting a vote.',
    (SocialCreateFormatV2.post, _SocialPostTool.quickPoll) =>
      'Ask one focused question that people can answer quickly.',
    (SocialCreateFormatV2.post, _SocialPostTool.quiz) =>
      'Build curiosity, then reveal the right answer clearly.',
    _ => 'Write an insight people will want to read and respond to.',
  };

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
        Container(
          key: const Key('screen04-create-writing-canvas'),
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDADBE8)),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 19,
                      backgroundColor: SocialV2Colors.navy,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.person_rounded, size: 19),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SocialV2Colors.navy,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            widget.authorHandle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SocialV2Colors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.public_rounded,
                      color: SocialV2Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Public',
                      style: TextStyle(
                        color: SocialV2Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('screen04-create-post-text'),
                  controller: _body,
                  focusNode: _bodyFocus,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 1200,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardAppearance: Brightness.light,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: switch (_format) {
                      SocialCreateFormatV2.reel =>
                        'Give people a reason to watch…',
                      SocialCreateFormatV2.carousel =>
                        'What connects this swipe story?',
                      SocialCreateFormatV2.post =>
                        question
                            ? _postTool == _SocialPostTool.quiz
                                  ? 'What will make people curious?'
                                  : 'Ask one clear, useful question…'
                            : 'Share a moment, insight or question…',
                    },
                    counterText: '',
                    hintStyle: const TextStyle(
                      color: Color(0xFF8B8DA4),
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const Divider(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = <Widget>[
                      _CreateCanvasInlineAction(
                        key: const Key('screen04-create-inline-emoji'),
                        icon: Icons.emoji_emotions_outlined,
                        label: 'Emoji',
                        onTap: () => unawaited(_openEmojiPalette()),
                      ),
                      _CreateCanvasInlineAction(
                        key: const Key('screen04-create-inline-mention'),
                        icon: Icons.alternate_email_rounded,
                        label: 'Mention',
                        onTap: () => _insertComposerText('@'),
                      ),
                      _CreateCanvasInlineAction(
                        key: const Key('screen04-create-inline-topic'),
                        icon: Icons.tag_rounded,
                        label: 'Topic',
                        onTap: () => _insertComposerText('#'),
                      ),
                      _CreateCanvasInlineAction(
                        key: const Key('screen04-create-inline-gif'),
                        icon: Icons.gif_box_outlined,
                        label: 'GIF',
                        onTap: _showGifAvailability,
                      ),
                    ];
                    final width = (constraints.maxWidth - 6) / 2;
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final action in actions)
                          SizedBox(width: width, child: action),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
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

class _CreateFeedPreview extends StatelessWidget {
  const _CreateFeedPreview({
    required this.authorName,
    required this.authorHandle,
    required this.body,
    required this.format,
    required this.tool,
    required this.media,
    required this.imagePollMedia,
    required this.choices,
    required this.onClose,
  });

  final String authorName;
  final String authorHandle;
  final String body;
  final SocialCreateFormatV2 format;
  final _SocialPostTool tool;
  final List<SocialPickedMedia> media;
  final List<SocialPickedMedia?> imagePollMedia;
  final List<String> choices;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final visibleChoices = choices
        .where((choice) => choice.trim().isNotEmpty)
        .toList(growable: false);
    return ListView(
      key: const Key('screen04-create-feed-preview'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview in Feed',
                    style: TextStyle(
                      color: SocialV2Colors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Check the reading experience before publishing.',
                    style: TextStyle(color: SocialV2Colors.muted),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('screen04-create-preview-close'),
              tooltip: 'Close Preview',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SocialV2Colors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x13000050),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: SocialV2Colors.navy,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.person_rounded),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(
                              color: SocialV2Colors.navy,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '$authorHandle · Now · Public',
                            style: const TextStyle(
                              color: SocialV2Colors.muted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_horiz_rounded),
                  ],
                ),
              ),
              if (body.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    body.trim(),
                    style: const TextStyle(
                      color: SocialV2Colors.ink,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (media.isNotEmpty)
                AspectRatio(
                  aspectRatio: format == SocialCreateFormatV2.carousel
                      ? 1.03
                      : 4 / 3,
                  child: SocialMediaPreviewV2(
                    path: media.first.path,
                    isAsset: media.first.isAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              if (tool == _SocialPostTool.imagePoll &&
                  imagePollMedia.any((item) => item != null))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item
                          in imagePollMedia.whereType<SocialPickedMedia>())
                        SizedBox(
                          width: 132,
                          height: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SocialMediaPreviewV2(
                              path: item.path,
                              isAsset: item.isAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (visibleChoices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      for (final choice in visibleChoices)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F6FC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SocialV2Colors.line),
                            ),
                            child: Text(
                              choice,
                              style: const TextStyle(
                                color: SocialV2Colors.navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.favorite_border_rounded),
                    Icon(Icons.chat_bubble_outline_rounded),
                    Icon(Icons.repeat_rounded),
                    Icon(Icons.share_outlined),
                    Icon(Icons.bookmark_border_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SocialV2Notice(
          title: 'Preview only',
          detail:
              'No reaction, reply, share or publish action is performed from Preview.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('screen04-create-preview-back-to-editing'),
          onPressed: onClose,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Back to editing'),
        ),
      ],
    );
  }
}

class _CreateCanvasStageRail extends StatelessWidget {
  const _CreateCanvasStageRail({required this.onPreview});

  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('screen04-create-stage-rail'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const _CreateCanvasStage(
          icon: Icons.edit_note_rounded,
          label: 'Build',
          active: true,
        ),
        const _CreateCanvasStageLine(),
        _CreateCanvasStage(
          key: const Key('screen04-create-open-preview'),
          icon: Icons.visibility_outlined,
          label: 'Preview',
          onTap: onPreview,
        ),
        const _CreateCanvasStageLine(),
        const _CreateCanvasStage(icon: Icons.public_rounded, label: 'Publish'),
      ],
    ),
  );
}

class _CreateCanvasStage extends StatelessWidget {
  const _CreateCanvasStage({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active || onTap != null
                    ? const Color(0xFF6D4AFF)
                    : SocialV2Colors.muted,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: active || onTap != null
                      ? SocialV2Colors.navy
                      : SocialV2Colors.muted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CreateCanvasStageLine extends StatelessWidget {
  const _CreateCanvasStageLine();

  @override
  Widget build(BuildContext context) => const Expanded(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 7),
      child: Divider(color: Color(0xFFD8D7E5)),
    ),
  );
}

class _CreateCanvasInlineAction extends StatelessWidget {
  const _CreateCanvasInlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(44),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      backgroundColor: const Color(0xFFF5F3FF),
      foregroundColor: SocialV2Colors.navy,
      side: const BorderSide(color: Color(0xFFE1DCFF)),
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
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
