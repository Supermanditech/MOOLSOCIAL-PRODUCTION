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

typedef _KeyboardCreateAction = ({
  Key key,
  Key? ownerKey,
  IconData icon,
  String label,
  bool selected,
  VoidCallback onTap,
});

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

  Future<void> _selectIntent(SocialCreateIntentV2 intent) async {
    final nextFormat = intent == SocialCreateIntentV2.carousel
        ? SocialCreateFormatV2.carousel
        : SocialCreateFormatV2.post;
    final nextTool = switch (intent) {
      SocialCreateIntentV2.image => _SocialPostTool.image,
      SocialCreateIntentV2.imagePoll => _SocialPostTool.imagePoll,
      SocialCreateIntentV2.quickPoll => _SocialPostTool.quickPoll,
      SocialCreateIntentV2.quiz => _SocialPostTool.quiz,
      _ => _SocialPostTool.none,
    };
    if (_format == nextFormat && _postTool == nextTool) {
      if (nextTool != _SocialPostTool.image) _bodyFocus.requestFocus();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _invalidateMediaSelection();
      _format = nextFormat;
      _postTool = nextTool;
      if (nextFormat == SocialCreateFormatV2.post &&
          nextTool != _SocialPostTool.image) {
        _media.clear();
      }
      _persistDraftState();
    });
    if (nextTool == _SocialPostTool.image) {
      await _choosePostImage();
    } else if (nextFormat == SocialCreateFormatV2.carousel &&
        _media.length < 2) {
      await _chooseCarousel();
    } else {
      _bodyFocus.requestFocus();
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

  Future<void> _choosePostImage([
    SocialMediaSource source = SocialMediaSource.gallery,
  ]) async {
    if (_selectingMedia) return;
    final request = ++_mediaSelectionRequest;
    setState(() => _selectingMedia = true);
    try {
      final selected = await widget.mediaPicker.pickImage(source);
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

  Future<void> _choosePostCameraImage() async {
    if (_format != SocialCreateFormatV2.post ||
        _postTool != _SocialPostTool.image) {
      HapticFeedback.selectionClick();
      setState(() {
        _invalidateMediaSelection();
        _format = SocialCreateFormatV2.post;
        _postTool = _SocialPostTool.image;
        _persistDraftState();
      });
    }
    await _choosePostImage(SocialMediaSource.camera);
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
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;
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
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _composerTitle,
                                maxLines: 1,
                                style: const TextStyle(
                                  color: SocialV2Colors.navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('screen04-create-open-preview'),
                          tooltip: 'Preview post',
                          onPressed: _openPreview,
                          icon: const Icon(Icons.visibility_outlined),
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
                            onPressed:
                                widget.previewOnly ||
                                    widget.session.busy ||
                                    _selectingMedia
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
                child: _buildWorkbenchCard(keyboardOpen),
              ),
            ),
            Material(
              key: const Key('screen04-create-format-decision'),
              color: Colors.white,
              elevation: 8,
              shadowColor: const Color(0x28000050),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                  child: _buildFormatDecisionBar(),
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

  Widget _buildFormatDecisionBar() {
    Widget compactAction({
      required Key key,
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
      double width = 44,
    }) => SizedBox(
      width: width,
      child: _FormatAction(
        key: key,
        icon: icon,
        label: label,
        selected: selected,
        onTap: onTap,
      ),
    );

    final actions = <_KeyboardCreateAction>[
      (
        key: const Key('screen04-create-tool-post'),
        ownerKey: const Key('social-create-moolsocial-post'),
        icon: Icons.edit_note_rounded,
        label: 'Text',
        selected:
            _format == SocialCreateFormatV2.post &&
            _postTool == _SocialPostTool.none,
        onTap: () => _selectIntent(SocialCreateIntentV2.text),
      ),
      (
        key: const Key('screen04-create-tool-image'),
        ownerKey: null,
        icon: Icons.image_outlined,
        label: 'Image',
        selected:
            _format == SocialCreateFormatV2.post &&
            _postTool == _SocialPostTool.image,
        onTap: () => _selectIntent(SocialCreateIntentV2.image),
      ),
      (
        key: const Key('screen04-create-tool-camera'),
        ownerKey: null,
        icon: Icons.photo_camera_outlined,
        label: 'Camera',
        selected: false,
        onTap: () => unawaited(_choosePostCameraImage()),
      ),
      (
        key: const Key('screen04-create-tool-carousel'),
        ownerKey: null,
        icon: Icons.view_carousel_outlined,
        label: 'Carousel',
        selected: _format == SocialCreateFormatV2.carousel,
        onTap: () => _selectIntent(SocialCreateIntentV2.carousel),
      ),
      (
        key: const Key('screen04-create-inline-gif'),
        ownerKey: null,
        icon: Icons.gif_box_outlined,
        label: 'GIF',
        selected: false,
        onTap: _showGifAvailability,
      ),
      (
        key: const Key('screen04-create-tool-image-poll'),
        ownerKey: null,
        icon: Icons.grid_view_rounded,
        label: 'Image Poll',
        selected:
            _format == SocialCreateFormatV2.post &&
            _postTool == _SocialPostTool.imagePoll,
        onTap: () => _selectIntent(SocialCreateIntentV2.imagePoll),
      ),
      (
        key: const Key('screen04-create-tool-quick-poll'),
        ownerKey: null,
        icon: Icons.poll_outlined,
        label: 'Quick Poll',
        selected:
            _format == SocialCreateFormatV2.post &&
            _postTool == _SocialPostTool.quickPoll,
        onTap: () => _selectIntent(SocialCreateIntentV2.quickPoll),
      ),
      (
        key: const Key('screen04-create-tool-quiz'),
        ownerKey: null,
        icon: Icons.check_circle_outline_rounded,
        label: 'Quiz',
        selected:
            _format == SocialCreateFormatV2.post &&
            _postTool == _SocialPostTool.quiz,
        onTap: () => _selectIntent(SocialCreateIntentV2.quiz),
      ),
      (
        key: const Key('screen04-create-inline-emoji'),
        ownerKey: null,
        icon: Icons.emoji_emotions_outlined,
        label: 'Emoji',
        selected: false,
        onTap: () => unawaited(_openEmojiPalette()),
      ),
      (
        key: const Key('screen04-create-inline-mention'),
        ownerKey: null,
        icon: Icons.alternate_email_rounded,
        label: 'Mention',
        selected: false,
        onTap: () => _insertComposerText('@'),
      ),
      (
        key: const Key('screen04-create-inline-topic'),
        ownerKey: null,
        icon: Icons.tag_rounded,
        label: 'Topic',
        selected: false,
        onTap: () => _insertComposerText('#'),
      ),
      if (widget.allowReel)
        (
          key: const Key('screen04-create-tool-reel'),
          ownerKey: null,
          icon: Icons.play_arrow_rounded,
          label: 'Reel',
          selected: _format == SocialCreateFormatV2.reel,
          onTap: _openReelSourcePicker,
        ),
      if (widget.onCreateYouTubeShort != null)
        (
          key: const Key('screen04-create-youtube-short'),
          ownerKey: null,
          icon: Icons.play_circle_outline_rounded,
          label: 'YouTube Short',
          selected: false,
          onTap: widget.onCreateYouTubeShort!,
        ),
    ];
    Widget action(_KeyboardCreateAction value) {
      final child = compactAction(
        key: value.key,
        icon: value.icon,
        label: value.label,
        selected: value.selected,
        onTap: value.onTap,
      );
      final ownerKey = value.ownerKey;
      return ownerKey == null
          ? child
          : KeyedSubtree(key: ownerKey, child: child);
    }

    return SizedBox(
      key: const ValueKey('create-keyboard-format-workbench'),
      height: 52,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              key: const Key('screen04-create-ime-format-strip'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    if (index > 0) const SizedBox(width: 3),
                    action(actions[index]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkbenchCard(bool keyboardOpen) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const Key('screen04-create-workbench'),
        padding: const EdgeInsets.all(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_draft.quotedPost case final quotedPost?) ...[
              SocialQuotedPostPreviewV2(
                key: const Key('social-create-quoted-post'),
                quotedPost: quotedPost,
              ),
              const SizedBox(height: 9),
            ],
            _buildWritingComposer(keyboardOpen),
            const SizedBox(height: 9),
            _buildFormatWorkspace(),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingComposer(bool keyboardOpen) {
    final question =
        _format == SocialCreateFormatV2.post &&
        (_postTool == _SocialPostTool.imagePoll ||
            _postTool == _SocialPostTool.quickPoll ||
            _postTool == _SocialPostTool.quiz);
    return Container(
      key: const Key('screen04-create-writing-canvas'),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
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
              minLines: keyboardOpen ? 3 : 5,
              maxLines: 12,
              maxLength: 1200,
              scrollPadding: const EdgeInsets.only(bottom: 104),
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
                  SocialCreateFormatV2.reel => 'Give people a reason to watch…',
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
          ],
        ),
      ),
    );
  }

  Widget _buildFormatWorkspace() {
    return Column(
      key: const ValueKey('screen04-create-post-workbench'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          scrollPadding: const EdgeInsets.only(bottom: 104),
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
                          scrollPadding: const EdgeInsets.only(bottom: 104),
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
      child: Tooltip(
        message: label,
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
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected ? Colors.white : SocialV2Colors.navy,
                  ),
                  if (selected)
                    const Positioned(
                      top: 3,
                      right: 3,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Colors.white,
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
