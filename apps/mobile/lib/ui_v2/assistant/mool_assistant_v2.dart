import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design/mool_design_system.dart' show MoolMotion;

import '../../core/design/mool_theme.dart';
import '../../features/assistant/mool_assistant.dart';
import '../../features/work/work_services.dart'
    show NativeWorkProofPicker, WorkProofSource, WorkPickedProof;
import '../../features/chat/chat_models.dart' show ChatAttachmentKind;
import '../../features/chat/chat_services.dart'
    show NativeChatAttachmentPicker, NativeChatVoiceRecorder,
      ChatAttachmentPicker, ChatPickedAttachment;

const _assistantLanguages = [
  ('English', 'English'),
  ('Auto', 'Automatic'),
  ('हिन्दी', 'हिन्दी'),
  ('मराठी', 'मराठी'),
  ('தமிழ்', 'தமிழ்'),
  ('اردو', 'اردو'),
  ('ಕನ್ನಡ', 'ಕನ್ನಡ'),
];

/// Reuses native media capture; product lists use the same Files control.
class MoolAssistantNativeMediaPicker implements ChatAttachmentPicker {
  MoolAssistantNativeMediaPicker({ChatAttachmentPicker? fallback,
    Future<WorkPickedProof?> Function()? documents})
    : _fallback = fallback ?? NativeChatAttachmentPicker(),
      _documents = documents ?? _readDocument;
  final ChatAttachmentPicker _fallback;
  final Future<WorkPickedProof?> Function() _documents;
  static const _maximum = 15 * 1024 * 1024;
  static const _types = {
    'pdf': 'application/pdf', 'txt': 'text/plain', 'csv': 'text/csv',
    'json': 'application/json',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  static Future<WorkPickedProof?> _readDocument() async {
    final file = await FilePicker.pickFile(type: FileType.custom,
      allowedExtensions: _types.keys.toList(growable: false));
    if (file == null) return null;
    final type = _types[file.name.split('.').last.toLowerCase()];
    if (type == null) throw const MoolAssistantDocumentException(
      MoolAssistantDocumentProblem.unsupported);
    if (await file.length() > _maximum) throw const MoolAssistantDocumentException(
      MoolAssistantDocumentProblem.tooLarge);
    final bytes = await file.readAsBytes();
    return WorkPickedProof(fileName: file.name, contentType: type, bytes: bytes);
  }

  @override Future<ChatPickedAttachment?> pick(ChatAttachmentKind kind) async {
    if (kind != ChatAttachmentKind.document) return _fallback.pick(kind);
    final proof = await _documents();
    if (proof == null) return null;
    if (!_types.values.contains(proof.contentType)) {
      throw const MoolAssistantDocumentException(MoolAssistantDocumentProblem.unsupported);
    }
    if (proof.bytes.isEmpty) {
      throw const MoolAssistantDocumentException(MoolAssistantDocumentProblem.empty);
    }
    if (proof.bytes.length > _maximum) {
      throw const MoolAssistantDocumentException(MoolAssistantDocumentProblem.tooLarge);
    }
    return ChatPickedAttachment(kind: kind, name: proof.fileName,
      contentType: proof.contentType, bytes: proof.bytes);
  }
}

/// Optional UI routing identity for adapters captured before the assistant push.
///
/// This binding grants no permission. Implementations retain their independently
/// admitted native owner, source and account guards. Bind only once; reject a
/// foreign navigator, rebinding, or an arbitrary route covering the native owner.
/// Route names are not proof of ownership. Nonimplementing adapters are unchanged.
abstract interface class MoolAssistantRouteBoundNativeAdapter
    implements MoolAssistantNativeAdapter {
  void bindAssistantRoute(Route<void> route, NavigatorState navigator);
}

/// Composition-only bridge: no account IDs are taken from routes or labels.
class MoolAssistantHost extends InheritedWidget {
  const MoolAssistantHost({
    required this.readContext,
    required this.contextChanges,
    required super.child,
    this.entitlements,
    this.historySource,
    super.key,
  });

  final MoolAssistantContext Function() readContext;
  final Listenable contextChanges;
  final MoolAssistantEntitlementSource? entitlements;
  final MoolAssistantHistorySource? historySource;

  static MoolAssistantHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MoolAssistantHost>();

  Future<void> open(BuildContext context) async {
    final workspace = context
        .getInheritedWidgetOfExactType<MoolAssistantWorkspaceScope>()
        ?.readWorkspace;
    final navigator = Navigator.of(context, rootNavigator: true);
    // Resolve once while the original owner is visible. Keep the exact adapter
    // instances for both controller dispatch and this route's identity binding.
    final nativeAdapters = (context
                .getInheritedWidgetOfExactType<MoolAssistantNativeScope>()
                ?.readAdapters(context) ??
            const <MoolAssistantNativeAdapter>[])
        .toList(growable: false);
    final controller = MoolAssistantController(
      currentContext: () => readContext().withWorkspace(workspace?.call()),
      contextChanges: contextChanges,
      entitlements: entitlements,
      historySource: historySource,
      nativeAdapters: nativeAdapters,
      attachments: NativeWorkProofPicker(),
      mediaPicker: MoolAssistantNativeMediaPicker(),
      voiceRecorder: NativeChatVoiceRecorder(),
    );
    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'mool-assistant'),
      fullscreenDialog: true,
      builder: (_) =>
          MoolAssistantPage(controller: controller, disposeController: true),
    );
    final bound = Set<MoolAssistantNativeAdapter>.identity();
    try {
      for (final adapter in nativeAdapters) {
        if (adapter is MoolAssistantRouteBoundNativeAdapter && bound.add(adapter)) {
          adapter.bindAssistantRoute(route, navigator);
        }
      }
    } on Object {
      // The page has not taken ownership; do not retain expiry timers/listeners.
      controller.dispose();
      rethrow;
    }
    await navigator.push<void>(route);
  }

  @override
  bool updateShouldNotify(MoolAssistantHost oldWidget) =>
      oldWidget.readContext != readContext ||
      oldWidget.entitlements != entitlements ||
      oldWidget.historySource != historySource;
}

/// Contextual native frontend capabilities. No model/provider or permission grant.
class MoolAssistantNativeScope extends InheritedWidget {
  const MoolAssistantNativeScope({
    required this.readAdapters,
    required super.child,
    super.key,
  });
  final Iterable<MoolAssistantNativeAdapter> Function(BuildContext)
  readAdapters;
  @override
  bool updateShouldNotify(MoolAssistantNativeScope oldWidget) =>
      oldWidget.readAdapters != readAdapters;
}

class MoolAssistantWorkspaceScope extends InheritedWidget {
  const MoolAssistantWorkspaceScope({
    required this.readWorkspace,
    required super.child,
    super.key,
  });

  final MoolAssistantWorkspace? Function() readWorkspace;

  @override
  bool updateShouldNotify(MoolAssistantWorkspaceScope oldWidget) =>
      oldWidget.readWorkspace != readWorkspace;
}

class MoolAssistantPage extends StatefulWidget {
  const MoolAssistantPage({
    required this.controller,
    this.disposeController = false,
    super.key,
  });

  final MoolAssistantController controller;
  final bool disposeController;

  @override
  State<MoolAssistantPage> createState() => _MoolAssistantPageState();
}

abstract final class _AssistantColors {
  static const accent = Color(0xFF0000FF);
  static const ink = Color(0xFF23252B);
  static const muted = Color(0xFF666A73);
}

ThemeData _assistantTheme(BuildContext context) {
  final theme = Theme.of(context);
  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(primary: _AssistantColors.accent, onSurface: _AssistantColors.ink),
    textTheme: theme.textTheme.apply(bodyColor: _AssistantColors.ink, displayColor: _AssistantColors.ink),
    iconTheme: theme.iconTheme.copyWith(color: _AssistantColors.ink),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: _AssistantColors.ink)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: _AssistantColors.accent, foregroundColor: Colors.white)),
  );
}

Duration _assistantMotionDuration(BuildContext context) =>
    MediaQuery.accessibleNavigationOf(context)
        ? Duration.zero
        : MoolMotion.accessible(context, const Duration(milliseconds: 260));

// Only the latest subtree exists: no outgoing private content or duplicate
// interactive controls are kept alive while a visual state changes.
class _AssistantReveal extends StatelessWidget {
  const _AssistantReveal({required this.stateKey, required this.child});
  final Object stateKey;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(stateKey),
    duration: _assistantMotionDuration(context),
    curve: MoolMotion.enter,
    tween: Tween(begin: _assistantMotionDuration(context) == Duration.zero ? 1 : 0, end: 1),
    builder: (_, value, child) => Transform.translate(offset: Offset(0, 12 * (1 - value)), child: Opacity(opacity: value, alwaysIncludeSemantics: true, child: child)),
    child: child,
  );
}

// One surface family across AI pages; gradients are static, not perpetual work.
class _AssistantSurface extends StatelessWidget {
  const _AssistantSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF8F9FB), child: child,
  );
}

class _AssistantWelcome extends StatelessWidget {
  const _AssistantWelcome({required this.store, required this.hasDraft});
  final bool store, hasDraft;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
    if (size.maxHeight < 280 || MediaQuery.textScalerOf(context).scale(1) > 1.5) {
      return const SizedBox.shrink();
    }
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        ExcludeSemantics(child: SizedBox(width: 76, height: 76, child: Stack(alignment: Alignment.center, children: [
          Transform.rotate(angle: -.15, child: Container(width: 58, height: 58,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF547EBD),
              boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 12))]))),
          Container(width: 60, height: 60, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF4569FF), _AssistantColors.accent, Color(0xFF0000FF)]),
            border: Border.all(color: Colors.white.withValues(alpha: .65))),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28)),
        ]))),
        const SizedBox(height: 18),
        const Text('Mool AI',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 1.2, fontWeight: FontWeight.w600, color: _AssistantColors.ink)),
        const SizedBox(height: 6),
        const Text('Skip the manual work. Just ask Mool AI.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _AssistantColors.ink)),
        const SizedBox(height: 8),
        Text(hasDraft ? 'Add the details you need. Review any proposed changes before confirming.' : store ? 'List from photos or CSV, record sales,\nrestock or manage accounts.' : 'Find products, compare options\nor track an order.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.5, color: _AssistantColors.muted)),
      ],
    )));
  });
}

// A finite three-example introduction, then the stable language guide. It never
// writes to the controller or repeats on keystrokes; reduced motion stays still.
class _AssistantHint extends StatelessWidget {
  const _AssistantHint({required this.store});
  final bool store;
  @override
  Widget build(BuildContext context) {
    const guide = 'Type or speak in your language';
    if (_assistantMotionDuration(context) == Duration.zero) return const Text(guide);
    final examples = store
      ? ['Try “Add a product from this photo”', 'Try “Import products from this CSV”', 'Try “Show my supplier dues”', guide]
      : ['Try “Find rice under ₹500”', 'Try “Track my order”', 'Try “Compare these products”', guide];
    return ExcludeSemantics(child: TweenAnimationBuilder<double>(
      key: ValueKey(store), duration: const Duration(seconds: 9), tween: Tween(begin: 0, end: 3),
      builder: (context, value, _) {
        final index = value.floor().clamp(0, 3);
        final entering = ((value - index) * 5).clamp(0.0, 1.0);
        return Transform.translate(offset: Offset(0, index == 0 || index == 3 ? 0 : 5 * (1 - entering)),
          child: Opacity(opacity: index == 0 || index == 3 ? 1 : .55 + .45 * entering,
            child: Text(examples[index], maxLines: 2, overflow: TextOverflow.ellipsis)));
      },
    ));
  }
}

class _MoolAssistantPageState extends State<MoolAssistantPage>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _focus = FocusNode();
  late int _epoch;
  bool _tasksOpen = false;
  bool _foreground = true;
  Timer? _feedbackCooldown;
  bool get _interactionCurrent => mounted && _foreground &&
      ModalRoute.of(context)?.isCurrent == true && widget.controller.canChangeConversation;

  void _visualFocusChanged() { if (mounted) setState(() {}); }
  void _selectionFeedback({bool sound = false}) {
    if (!_interactionCurrent || _feedbackCooldown?.isActive == true) return;
    _feedbackCooldown = Timer(MoolMotion.quick, () => _feedbackCooldown = null);
    // Android CLOCK_TICK is unsupported on some devices; VIRTUAL_KEY uses
    // the platform's standard light feedback and respects system preferences.
    final feedback = Theme.of(context).platform == TargetPlatform.android
        ? HapticFeedback.lightImpact
        : HapticFeedback.selectionClick;
    unawaited(feedback().catchError((Object _) {}));
    if (sound) unawaited(SystemSound.play(SystemSoundType.click).catchError((Object _) {}));
  }

  String? _shownProposalId;
  String? _composerPanel;
  final _choiceScroll = ScrollController(keepScrollOffset: false);
  final _toolbarScroll = ScrollController(keepScrollOffset: false);
  int? _languageEpoch;
  Object? _languageBinding;
  final _taskSearch = TextEditingController();
  final _taskSearchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _epoch = widget.controller.epoch;
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _focus.addListener(_visualFocusChanged);
    _input.text = widget.controller.draft;
    widget.controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
  }

  void _changed() {
    if (!mounted) return;
    if (_epoch != widget.controller.epoch) {
      _epoch = widget.controller.epoch;
      _tasksOpen = false;
      _taskSearch.clear();
      _composerPanel = null;
      _taskSearchFocus.unfocus();
      _input.value = TextEditingValue(
        text: widget.controller.draft,
        selection: TextSelection.collapsed(
          offset: widget.controller.draft.length,
        ),
      );
      _focus.unfocus();
    }
    final nextProposal = widget.controller.proposal?.id;
    if (nextProposal != _shownProposalId) {
      _shownProposalId = nextProposal;
      if (nextProposal != null) {
        _tasksOpen = false;
        _taskSearch.clear();
        _taskSearchFocus.unfocus();
        _composerPanel = null;
      }
    }
    if (widget.controller.recording || widget.controller.voiceBusy) {
      _composerPanel = null;
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    widget.controller.setForeground(_foreground);
    if (state == AppLifecycleState.resumed) widget.controller.synchronize();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.controller.cancelVoice();
    }
  }

  void _closeComposerPanel() {
    if (!mounted) return;
    setState(() {
      _composerPanel = null;
    });
  }

  Future<void> _reviewNativeProposal() async {
    final controller = widget.controller;
    controller.synchronize();
    final binding = controller.context.binding;
    final route = ModalRoute.of(context);
    _focus.unfocus();
    _taskSearchFocus.unfocus();
    final result = await controller.reviewProposal();
    if (!mounted ||
        !identical(controller, widget.controller) ||
        result != MoolAssistantReviewResult.returnToOwner)
      return;
    controller.synchronize();
    if (controller.context.binding != binding ||
        route == null ||
        !route.isCurrent ||
        route.settings.name != 'mool-assistant')
      return;
    // Returning to the underlying form disposes this owned controller. Preserve
    // its exact request first, or use the existing explicit discard barrier.
    final saved =
        controller.historySource != null &&
        await controller.changeConversation();
    if (!mounted ||
        !identical(controller, widget.controller) ||
        controller.context.binding != binding ||
        !route.isCurrent)
      return;
    if (!saved) {
      await _requestClose();
      return;
    }
    final epoch = controller.epoch;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        controller.context.binding != binding ||
        controller.epoch != epoch ||
        !route.isCurrent ||
        _pendingInput)
      return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop();
  }

  void _toggleComposerPanel(String panel) {
    final c = widget.controller;
    c.synchronize();
    if (!_interactionCurrent) return;
    final opening = _composerPanel != panel;
    _focus.unfocus();
    _taskSearchFocus.unfocus();
    setState(() {
      _composerPanel = _composerPanel == panel ? null : panel;
      _languageEpoch = c.epoch;
      _languageBinding = c.context.binding;
    });
    if (opening) _selectionFeedback();
  }

  bool _currentPanel(String panel) {
    final c = widget.controller;
    c.synchronize();
    return _interactionCurrent &&
        _composerPanel == panel &&
        _languageEpoch == c.epoch &&
        _languageBinding == c.context.binding;
  }

  void _chooseLanguage(String value) {
    if (!_currentPanel('language')) return;
    if (!_assistantLanguages.any((item) => item.$1 == value)) return;
    final before = widget.controller.language;
    widget.controller.chooseLanguage(value);
    _closeComposerPanel();
    if (widget.controller.language != before) _selectionFeedback();
  }

  void _chooseInput() => _toggleComposerPanel('media');

  Future<void> _pickInput(String choice) async {
    if (!_currentPanel('media')) return;
    final c = widget.controller;
    _closeComposerPanel();
    switch (choice) {
      case 'camera':
        await c.pickAttachment(WorkProofSource.camera);
      case 'photos':
        await c.pickAttachment(WorkProofSource.gallery);
      case 'files':
        await c.pickMedia(ChatAttachmentKind.document);
      case 'video':
        await c.pickMedia(ChatAttachmentKind.video);
    }
  }

  Widget _composerChoices() {
    final c = widget.controller;
    final media = _composerPanel == 'media';
    final choices = <Widget>[
      if (media)
        for (final item in const [
          ('camera', 'Camera', Icons.photo_camera_outlined),
          ('photos', 'Photos', Icons.photo_library_outlined),
          ('files', 'Files', Icons.attach_file),
          ('video', 'Video', Icons.videocam_outlined),
        ])
          TextButton.icon(
            key: ValueKey('assistant-media-${item.$1}'),
            onPressed: () => _pickInput(item.$1),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: Colors.white.withValues(alpha: .55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(item.$3, size: 20, color: _AssistantColors.muted),
            label: Text(item.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          )
      else
        for (final item in _assistantLanguages)
          Tooltip(
            message: item.$1 == 'Auto'
                ? 'Automatic — reply in my language'
                : item.$2,
            child: Semantics(
              selected: item.$1 == c.language,
              child: TextButton(
                key: ValueKey('assistant-language-${item.$1}'),
                onPressed: () => _chooseLanguage(item.$1),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: item.$1 == c.language
                      ? const Color(0xFFD7E4FF)
                      : Colors.white.withValues(alpha: .55),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.$1 == c.language) ...[
                      const Icon(Icons.check, size: 18, color: _AssistantColors.ink),
                      const SizedBox(width: 4),
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    ];
    return Padding(
      key: Key(
        media
            ? 'mool-assistant-media-choices'
            : 'mool-assistant-language-choices',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: RawScrollbar(
              controller: _choiceScroll,
              thumbVisibility: true,
              thickness: 2,
              radius: const Radius.circular(2),
              thumbColor: _AssistantColors.muted.withValues(alpha: .4),
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                controller: _choiceScroll,
                key: const Key('mool-assistant-choice-strip'),
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                child: Row(children: choices),
              ),
            ),
          ),
          IconButton(
            tooltip: media ? 'Close media choices' : 'Close language choices',
            onPressed: _closeComposerPanel,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  void _openSearch() {
    if (!_interactionCurrent) return;
    setState(() {
      _composerPanel = null;
      _tasksOpen = true;
    });
  }

  void _showActions() {
    if (!_interactionCurrent) return;
    if (_tasksOpen) {
      _backTasks();
      return;
    }
    _focus.unfocus();
    _taskSearchFocus.unfocus();
    setState(() {
      _composerPanel = null;
      _tasksOpen = true;
      _taskSearch.clear();
    });
    _selectionFeedback();
  }

  void _backTasks() => _closeTasks();

  void _closeTasks() {
    _taskSearchFocus.unfocus();
    setState(() {
      _tasksOpen = false;
      _taskSearch.clear();
    });
  }



  Future<void> _selectAction(String id) async {
    if (!_interactionCurrent) return;
    final c = widget.controller;
    c.synchronize();
    final action = c.actions().where((a) => a.id == id).firstOrNull;
    if (action == null) return;
    final epoch = c.epoch, binding = c.context.binding, draft = c.draft;
    var replace = false;
    if (draft.trim().isNotEmpty && draft != action.request) {
      replace =
          await showDialog<bool>(
            context: context,
            animationStyle: AnimationStyle(duration: _assistantMotionDuration(context), reverseDuration: _assistantMotionDuration(context)),
            builder: (dialog) => _assistantDialog(
              context,
              title: const Text('Replace your request?'),
              content: const Text(
                'Your typed request will be replaced. Any attached files will be kept.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog, false),
                  child: const Text('Keep editing'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialog, true),
                  child: const Text('Use task'),
                ),
              ],
            ),
          ) ??
          false;
      if (!replace) return;
    }
    if (!mounted ||
        epoch != c.epoch ||
        binding != c.context.binding ||
        draft != c.draft) {
      return;
    }
    if (c.chooseAction(id, replaceDraft: replace)) {
      _selectionFeedback(sound: true);
      _closeTasks();
      _input.value = TextEditingValue(
        text: c.draft,
        selection: TextSelection.collapsed(offset: c.draft.length),
      );
      _focus.requestFocus();
    }
  }

  Widget _buildHeader() => Padding(
    key: const Key('mool-assistant-header'),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        IconButton(
          key: const Key('mool-assistant-history'),
          tooltip: 'History',
          onPressed: widget.controller.canChangeConversation
              ? _showHistory
              : null,
          icon: const SizedBox(
            width: 20,
            height: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 2,
                  child: ColoredBox(color: _AssistantColors.muted),
                ),
                SizedBox(
                  width: 12,
                  height: 2,
                  child: ColoredBox(color: _AssistantColors.muted),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: MergeSemantics(
            child: TextField(
              key: const Key('mool-assistant-action-search'),
              controller: _taskSearch,
              focusNode: _taskSearchFocus,
              enabled: widget.controller.canChangeConversation,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.search,
              onTap: _openSearch,
              onChanged: (_) => _openSearch(),
              onSubmitted: (_) => _taskSearchFocus.unfocus(),
              decoration: InputDecoration(
                hintText:
                    MediaQuery.sizeOf(context).width < 360 &&
                        MediaQuery.textScalerOf(context).scale(1) > 1.35
                    ? 'Search'
                    : 'Search tasks',
                prefixIcon: const Icon(Icons.search,
                  key: Key('mool-assistant-search-icon'), size: 20, color: _AssistantColors.accent),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                isDense: true,
                constraints: const BoxConstraints(minHeight: 48),
              ),
            ),
          ),
        ),
        if (_taskSearch.text.isNotEmpty)
          IconButton(
            tooltip: 'Clear task search',
            onPressed: () {
              _taskSearch.clear();
              _openSearch();
            },
            icon: const Icon(Icons.cancel_outlined, size: 20),
          ),
        if (!_tasksOpen)
          IconButton(
            key: const Key('mool-assistant-new-chat'),
            tooltip: 'New chat',
            onPressed: widget.controller.canChangeConversation
                ? () async {
                    _focus.unfocus();
                    _taskSearchFocus.unfocus();
                    await widget.controller.changeConversation();
                  }
                : null,
            icon: const Icon(Icons.edit_square, size: 20),
          ),
        IconButton(
          key: const Key('mool-assistant-back'),
          tooltip: 'Close Mool AI',
          onPressed: _requestClose,
          icon: const Icon(Icons.close, size: 21),
        ),
      ],
    ),
  );

  bool _historyOpen = false;
  final _attachmentScroll = ScrollController();
  bool _closePromptOpen = false;
  bool get _pendingInput =>
      widget.controller.hasInput ||
      widget.controller.recording ||
      widget.controller.voiceBusy ||
      widget.controller.pickingAttachment ||
      widget.controller.historyBusy;

  Future<void> _requestClose() async {
    if (!mounted || _closePromptOpen) return;
    final c = widget.controller;
    c.synchronize();
    _closeComposerPanel();
    if (!_pendingInput) {
      if (_tasksOpen) {
        _closeTasks();
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!mounted) return;
      await Navigator.of(context).maybePop();
      return;
    }
    final epoch = c.epoch, binding = c.context.binding;
    _closePromptOpen = true;
    final choice = await showDialog<String>(
      context: context,
      animationStyle: AnimationStyle(duration: _assistantMotionDuration(context), reverseDuration: _assistantMotionDuration(context)),
      builder: (dialog) => _assistantDialog(
        context,
        scrollable: true,
        title: Text(
          c.historyBusy ? 'Saving your request' : 'Keep your request?',
        ),
        content: Text(
          c.historyBusy
              ? 'Wait for the save result before leaving this chat.'
              : c.historySource == null
              ? 'This request has not been saved. Keep editing or discard this draft.'
              : 'Save this request to continue later, or discard this draft.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, 'keep'),
            child: const Text('Keep editing'),
          ),
          if (!c.historyBusy)
            TextButton(
              onPressed: () => Navigator.pop(dialog, 'discard'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Discard draft'),
            ),
          if (c.historySource != null &&
              c.context.signedIn &&
              c.canChangeConversation)
            FilledButton(
              onPressed: () => Navigator.pop(dialog, 'save'),
              child: const Text('Save & close'),
            ),
        ],
      ),
    );
    _closePromptOpen = false;
    if (!mounted || epoch != c.epoch || binding != c.context.binding) return;
    if (choice == 'save') {
      if (!await c.changeConversation() ||
          !mounted ||
          binding != c.context.binding) {
        return;
      }
    } else if (choice == 'discard') {
      if (!c.discardDraft()) return;
    } else {
      return;
    }
    if (!mounted) return;
    if (_tasksOpen) _closeTasks();
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && binding == c.context.binding && !_pendingInput) {
      await Navigator.of(context).maybePop();
    }
  }

  IconData _attachmentIcon(String type) {
    if (type.startsWith('audio/')) return Icons.mic_none;
    if (type.startsWith('video/')) return Icons.videocam_outlined;
    if (type.startsWith('image/')) return Icons.photo_outlined;
    if (type == 'application/pdf') return Icons.picture_as_pdf_outlined;
    return Icons.attach_file;
  }

  String _attachmentDetail(MoolAssistantAttachment item) {
    if (item.contentType.startsWith('audio/')) {
      final duration = item.duration;
      return duration == null
          ? 'Voice'
          : 'Voice ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    if (item.contentType.startsWith('video/')) return 'Video';
    if (item.contentType.startsWith('image/')) return 'Photo';
    return item.contentType == 'application/pdf' ? 'PDF' : 'File';
  }

  Future<void> _showHistory() async {
    if (!_interactionCurrent) return;
    _selectionFeedback();
    final controller = widget.controller, epoch = widget.controller.epoch;
    _closeComposerPanel();
    _focus.unfocus();
    _taskSearchFocus.unfocus();
    unawaited(controller.loadHistory());
    setState(() => _historyOpen = true);
    final id = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss history panel',
      barrierColor: Colors.black54,
      transitionDuration: _assistantMotionDuration(context),
      pageBuilder: (panel, _, _) => SizedBox.expand(
        key: const Key('mool-assistant-history-panel'),
        child: Theme(data: _assistantTheme(context), child: Material(
          color: const Color(0xFFF8F9FB),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(panel).bottom),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _AssistantHistory(controller: controller),
              ),
            ),
          ),
        )),
      ),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: child,
      ),
    );
    if (mounted) setState(() => _historyOpen = false);
    if (!mounted || id == null || epoch != controller.epoch) return;
    await controller.changeConversation(id: id);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedbackCooldown?.cancel();
    _focus.removeListener(_visualFocusChanged);
    widget.controller.removeListener(_changed);
    if (widget.disposeController) widget.controller.dispose();
    _attachmentScroll.dispose();
    _choiceScroll.dispose();
    _toolbarScroll.dispose();
    _input.dispose();
    _focus.dispose();
    _taskSearch.dispose();
    _taskSearchFocus.dispose();
    super.dispose();
  }

  bool get _inlineStatus =>
      widget.controller.notice == null &&
      widget.controller.selectedAttachments.length <= 1 &&
      MediaQuery.textScalerOf(context).scale(1) <= 1.35;

  String _shortAccessText(MoolAssistantController c) => switch (c.access) {
    MoolAssistantAccess.checking => 'Checking access…',
    MoolAssistantAccess.subscriptionRequired ||
    MoolAssistantAccess.revoked => 'AI inactive',
    MoolAssistantAccess.purchasePending => 'Confirmation pending',
    MoolAssistantAccess.expired => 'Access expired',
    _ => 'AI unavailable',
  };

  Widget _composerLane() {
    final c = widget.controller;
    final recording = c.recording || c.voiceBusy;
    final mediaEnabled = !c.pickingAttachment && !c.voiceBusy && !c.recording && !c.reviewBusy;
    final speakEnabled = !c.voiceBusy && !c.pickingAttachment && !c.reviewBusy;
    final height = math.max(
      48.0,
      MediaQuery.textScalerOf(context).scale(14) * 1.4 + 16,
    );
    if (!recording && _composerPanel != null) {
      return _AssistantReveal(stateKey: 'panel:$_composerPanel', child: SizedBox(
        key: const Key('mool-assistant-control-lane'),
        height: height,
        child: _composerChoices(),
      ));
    }
    final controls = <Widget>[
      if (recording) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            c.voiceBusy
                ? 'Preparing voice…'
                : 'Recording ${c.voiceDuration.inMinutes}:${(c.voiceDuration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        if (c.recording && !c.voiceBusy)
          TextButton.icon(
            key: const Key('mool-assistant-voice'),
            onPressed: c.toggleVoice,
            icon: Icon(
              Icons.stop_circle_outlined,
              size: 20,
              color: Colors.red.shade700,
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            label: const Text('Stop', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        TextButton(
          onPressed: c.cancelVoice,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ] else ...[
        IconButton(
          key: const Key('mool-assistant-attach'),
          tooltip: 'Add media',
          onPressed: mediaEnabled ? _chooseInput : null,
          icon: Icon(Icons.add, size: 20, color: mediaEnabled ? _AssistantColors.muted : Theme.of(context).disabledColor),
        ),
        Semantics(selected: _tasksOpen, child: TextButton.icon(
          key: const Key('mool-assistant-actions'),
          onPressed: c.canChangeConversation ? _showActions : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            backgroundColor: _tasksOpen
                ? _AssistantColors.accent.withValues(alpha: .10)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: Icon(Icons.checklist_rounded, size: 20, color: c.canChangeConversation ? _AssistantColors.muted : Theme.of(context).disabledColor),
          label: const Text('Tasks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        )),
        TextButton.icon(
          key: const Key('mool-assistant-voice'),
          onPressed: !speakEnabled
              ? null
              : () {
                  _focus.unfocus();
                  c.toggleVoice();
                },
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: Icon(Icons.mic_none_outlined, size: 20, color: speakEnabled ? _AssistantColors.muted : Theme.of(context).disabledColor),
          label: const Text('Speak', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        IconButton(
          key: const Key('mool-assistant-language'),
          tooltip: 'Language: ${c.language}',
          onPressed: c.canChangeConversation
              ? () => _toggleComposerPanel('language')
              : null,
          icon: Icon(Icons.language, size: 20, color: c.canChangeConversation ? _AssistantColors.muted : Theme.of(context).disabledColor),
        ),
        const IconButton(
          key: Key('mool-assistant-send'),
          tooltip: 'AI is unavailable right now',
          onPressed: null,
          icon: Icon(Icons.arrow_upward, size: 20),
          constraints: BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    ];
    return _AssistantReveal(stateKey: recording ? 'voice' : 'tools', child: SizedBox(
      key: const Key('mool-assistant-control-lane'),
      height: height,
      child: LayoutBuilder(
        builder: (context, layout) => RawScrollbar(
          controller: _toolbarScroll,
          thumbVisibility: true,
          thickness: 2,
          radius: const Radius.circular(2),
          thumbColor: _AssistantColors.muted.withValues(alpha: .4),
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _toolbarScroll,
            key: ValueKey(
              recording
                  ? 'mool-assistant-recording-strip'
                  : 'mool-assistant-toolbar-strip',
            ),
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: layout.maxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: controls,
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _composerCaption() {
    final c = widget.controller;
    final contextName = c.context.inWorkspace
        ? 'Store · ${c.context.workspaceName ?? "Workspace"}'
        : 'Buy';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: c.context.inWorkspace
                      ? 'Workspace: ${c.context.workspaceName ?? "Store"}'
                      : 'Buy · Personal account',
                  child: Text(
                    contextName,
                    key: const Key('mool-assistant-context'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _AssistantColors.muted,
                    ),
                  ),
                ),
              ),
              if (c.language != 'Auto' &&
                  MediaQuery.textScalerOf(context).scale(1) <= 1.35)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: 'Reply language: ${c.language}',
                      child: Text(
                        c.language,
                        key: const Key('mool-assistant-selected-language'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _AssistantColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_inlineStatus)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Tooltip(
                    message: _accessText(c),
                    child: Semantics(
                      label: _accessText(c),
                      excludeSemantics: true,
                      liveRegion: true,
                      child: Text(
                        _shortAccessText(c),
                        key: const Key('mool-assistant-access'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: _AssistantColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              if (c.selectedAttachments.length > 1)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${c.selectedAttachments.length} attachments',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _AssistantColors.muted,
                    ),
                  ),
                ),
            ],
          ),
          if (c.language != 'Auto' &&
              MediaQuery.textScalerOf(context).scale(1) > 1.35)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Tooltip(
                message: 'Reply language: ${c.language}',
                child: Text(
                  c.language,
                  key: const Key('mool-assistant-selected-language'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: _AssistantColors.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _composerStatus() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
    child: Semantics(
      liveRegion: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.controller.notice ?? _accessText(widget.controller),
          key: const Key('mool-assistant-access'),
          style: const TextStyle(
            fontSize: 12,
            color: _AssistantColors.muted,
            height: 1.3,
          ),
        ),
      ),
    ),
  );

  Widget _attachmentStrip() {
    final c = widget.controller;
    return SizedBox(
      height: math.max(
        48,
        MediaQuery.textScalerOf(context).scale(12) * 2.8 + 12,
      ),
      child: Scrollbar(
        controller: _attachmentScroll,
        thumbVisibility: c.selectedAttachments.length > 1,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _attachmentScroll,
          key: const Key('mool-assistant-attachment-strip'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Row(
            children: [
              for (var i = 0; i < c.selectedAttachments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: math.max(
                      220,
                      math.min(
                        320,
                        MediaQuery.textScalerOf(context).scale(110) + 110,
                      ),
                    ),
                    child: Material(
                      color: MoolColors.canvas,
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Icon(
                            _attachmentIcon(
                              c.selectedAttachments[i].contentType,
                            ),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Tooltip(
                              message: c.selectedAttachments[i].fileName,
                              triggerMode: TooltipTriggerMode.tap,
                              child: Semantics(
                                label:
                                    '${c.selectedAttachments[i].fileName}, ${_attachmentDetail(c.selectedAttachments[i])}',
                                excludeSemantics: true,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.selectedAttachments[i].fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      _attachmentDetail(
                                        c.selectedAttachments[i],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _AssistantColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip:
                                'Remove ${c.selectedAttachments[i].fileName}',
                            constraints: const BoxConstraints.tightFor(
                              width: 48,
                              height: 48,
                            ),
                            visualDensity: VisualDensity.standard,
                            padding: EdgeInsets.zero,
                            onPressed: c.historyBusy
                                ? null
                                : () => c.removeSelectedAttachment(i),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
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

  String _accessText(MoolAssistantController controller) =>
      switch (controller.access) {
        MoolAssistantAccess.checking => 'Checking AI access…',
        MoolAssistantAccess.subscriptionRequired => 'AI access is inactive.',
        MoolAssistantAccess.purchasePending =>
          'AI access is awaiting confirmation.',
        MoolAssistantAccess.expired => 'AI access has expired.',
        MoolAssistantAccess.revoked => 'AI access is inactive.',
        MoolAssistantAccess.active => 'AI is unavailable right now.',
        MoolAssistantAccess.unavailable => 'AI is unavailable right now.',
      };

  // Reserve only the presentation's actual footer needs. A text-scale-only
  // floor needlessly hid the empty composer in wide, short viewports.
  // Use physical safe-area/keyboard insets. Legacy `uiautomator dump` clips
  // bounds to Display.getSize; raw accessibility bounds verify the real area.
  static const double _composerBottomGap = 4;

  double _minimumContentHeight(BuildContext context, double width) {
    final c = widget.controller;
    final scaler = MediaQuery.textScalerOf(context);
    final composerWidth = math.max(1.0, math.min(640.0, width - 24));
    double measure(
      String text,
      TextStyle style,
      double available, {
      int? maxLines,
    }) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: maxLines,
      )..layout(maxWidth: math.max(1, available));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final style = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final request = measure(
      c.draft.isEmpty ? 'Type or speak in your language' : c.draft,
      style.copyWith(fontSize: 14),
      composerWidth - 40,
      maxLines: 4,
    );
    final notice = _inlineStatus
        ? 0.0
        : measure(
            c.notice ?? _accessText(c),
            style.copyWith(fontSize: 12, height: 1.3),
            width - 32,
          );
    final caption = measure(
      'Buy',
      style.copyWith(fontSize: 12),
      composerWidth - 32,
      maxLines: 1,
    );
    final tools = math.max(48.0, scaler.scale(14) * 1.4 + 16);
    final attachments = c.selectedAttachments.isEmpty
        ? 0.0
        : math.max(48.0, scaler.scale(12) * 2.8 + 12) + 8;
    final languageCaption = c.language != 'Auto' && scaler.scale(1) > 1.35
        ? measure(
                c.language,
                style.copyWith(fontSize: 12),
                composerWidth - 32,
                maxLines: 1,
              ) +
              4
        : 0.0;
    return 52 + _composerBottomGap +
        tools +
        request +
        notice +
        caption +
        languageCaption +
        attachments;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final preparationBatch=controller.preparationBatch;
    final preparationSize=preparationBatch==null?0:preparationBatch.items.length+1;
    final selectedPreparationIndex=controller.proposal==null?-1:
      preparationBatch?.items.indexWhere((item)=>item.proposal?.id==controller.proposal!.id)??-1;
    final proposalListIndex=controller.messages.length+
      (selectedPreparationIndex<0?preparationSize:selectedPreparationIndex+2);
    return PopScope<Object?>(
      canPop: !_pendingInput && !_tasksOpen && _composerPanel == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_composerPanel != null) {
            _closeComposerPanel();
          } else if (_tasksOpen) {
            _backTasks();
          } else {
            unawaited(_requestClose());
          }
        }
      },
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            visualDensity: VisualDensity.standard,
            padding: const EdgeInsets.all(8),
          ),
        ),
        child: Theme(data: _assistantTheme(context), child: Scaffold(
          key: const Key('mool-assistant-page'),
          backgroundColor: MoolColors.canvas,
          body: _AssistantSurface(child: SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ExcludeSemantics(
                    excluding: _historyOpen,
                    child: IgnorePointer(
                      ignoring: _historyOpen,
                      child: Opacity(
                        opacity: _historyOpen ? 0 : 1,
                        child: _buildHeader(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        key: const Key('mool-assistant-viewport'),
                        child: SizedBox(
                          height: math.max(
                            constraints.maxHeight,
                            _minimumContentHeight(
                              context,
                              constraints.maxWidth,
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: _AssistantReveal(stateKey: _tasksOpen,
                                child: _tasksOpen
                                    ? _AssistantActions(
                                        controller: controller,
                                        query: _taskSearch.text,
                                        onSelected: _selectAction,
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (controller.conversationTitle
                                              case final title?)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    16,
                                                    10,
                                                    16,
                                                    2,
                                                  ),
                                              child: Tooltip(
                                                message: title,
                                                child: Text(
                                                  title,
                                                  key: const Key(
                                                    'mool-assistant-conversation-title',
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (controller.messages.isEmpty && controller.proposal == null && preparationBatch == null && controller.proposalNotice == null)
                                            Expanded(child: _AssistantWelcome(store: controller.context.inWorkspace, hasDraft: controller.hasInput))
                                          else Expanded(
                                            child: ListView.builder(
                                              key: const Key(
                                                'mool-assistant-content',
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              itemCount:
                                                  controller.messages.length +
                                                  (preparationBatch == null ? 0 : preparationBatch.items.length+1) +
                                                  (controller.proposal == null
                                                      ? 0
                                                      : 1) +
                                                  (controller.proposalNotice ==
                                                          null
                                                      ? 0
                                                      : 1),
                                              itemBuilder: (context, index) {
                                                if (index >=
                                                    controller
                                                        .messages
                                                        .length) {
                                                  final batch=preparationBatch;
                                                  final batchIndex=index-controller.messages.length-
                                                    (controller.proposal!=null && index>proposalListIndex?1:0);
                                                  if(index!=proposalListIndex || controller.proposal==null){
                                                  if(batch!=null && batchIndex<preparationSize){
                                                    if(batchIndex==0)return MoolAssistantPreparationCard(controller:controller,batch:batch);
                                                    final item=batch.items[batchIndex-1];
                                                    return MoolAssistantPreparationRow(key:ValueKey('assistant-preparation-${item.id}'),controller:controller,item:item);
                                                  }
                                                  }
                                                  final value =
                                                      controller.proposal;
                                                  if (value != null &&
                                                      index ==
                                                          proposalListIndex) {
                                                    return _AssistantReveal(stateKey: 'proposal:${value.id}', child: MoolAssistantProposalCard(
                                                      key: ValueKey(
                                                        'assistant-proposal-${value.id}',
                                                      ),
                                                      title: value.title,
                                                      summary: value.summary,
                                                      busy:
                                                          controller.reviewBusy,
                                                      onReview:
                                                          controller
                                                              .canChangeConversation
                                                          ? () {
                                                              unawaited(
                                                                _reviewNativeProposal(),
                                                              );
                                                            }
                                                          : null,
                                                      onCancel: controller
                                                          .cancelProposal,
                                                    ));
                                                  }
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    child: Semantics(
                                                      liveRegion: true,
                                                      child: Text(
                                                        controller
                                                                .proposalNotice ??
                                                            '',
                                                        key: const Key(
                                                          'mool-assistant-proposal-notice',
                                                        ),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              _AssistantColors.muted,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                final message =
                                                    controller.messages[index];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 14,
                                                      ),
                                                  child: Align(
                                                    alignment: message.$1
                                                        ? Alignment.centerRight
                                                        : Alignment.centerLeft,
                                                    child: ConstrainedBox(
                                                      constraints:
                                                          BoxConstraints(
                                                            maxWidth: math.min(
                                                              640,
                                                              constraints
                                                                      .maxWidth *
                                                                  .9,
                                                            ),
                                                          ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            message.$1
                                                            ? CrossAxisAlignment
                                                                  .end
                                                            : CrossAxisAlignment
                                                                  .start,
                                                        children: [
                                                          Text(
                                                            message.$1
                                                                ? 'You'
                                                                : 'Assistant',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      MoolColors
                                                                          .muted,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          DecoratedBox(
                                                            decoration: BoxDecoration(
                                                              color: message.$1
                                                                  ? const Color(0xFFF0F1F4)
                                                                  : Colors.white.withValues(alpha: .8),
                                                              border: Border.all(color: const Color(0xFFE0E2E7)),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              child: SelectableText(
                                                                message.$2,
                                                                style:
                                                                    const TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      height:
                                                                          1.4,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  12, 4, 12, _composerBottomGap,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 640,
                                    ),
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _composerCaption()),
                                      const SizedBox(height: 3),
                                      AnimatedContainer(
                                      key: const Key('mool-assistant-composer'),
                                      duration: _assistantMotionDuration(context),
                                      curve: MoolMotion.change,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 4))],
                                        border: Border.all(
                                          color: _focus.hasFocus ? _AssistantColors.accent : const Color(0xFFD8DAE0),
                                          width: 1.25,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          4,
                                          2,
                                          4,
                                          2,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!_inlineStatus)
                                              _composerStatus(),
                                            if (controller
                                                .selectedAttachments
                                                .isNotEmpty)
                                              _attachmentStrip(),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Semantics(
                                                label: 'Your request. Type or speak in your language',
                                                child: TextField(
                                                  key: const Key(
                                                    'mool-assistant-input',
                                                  ),
                                                  controller: _input,
                                                  focusNode: _focus,
                                                  onChanged:
                                                      controller.setDraft,
                                                  readOnly:
                                                      controller.recording ||
                                                      controller.voiceBusy,
                                                  minLines: 1,
                                                  maxLines: 3,
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  textInputAction:
                                                      TextInputAction.newline,
                                                  decoration: InputDecoration(
                                                    hint: _focus.hasFocus || controller.draft.isNotEmpty || controller.recording || controller.voiceBusy
                                                      ? const Text('Type or speak in your language')
                                                      : _AssistantHint(store: controller.context.inWorkspace),
                                                    isDense: true,
                                                    constraints: const BoxConstraints(minHeight: 44),
                                                    border: InputBorder.none,
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    filled: false,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 4,
                                                          horizontal: 4,
                                                        ),
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            _composerLane(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        )),
      ),
    );
  }
}

// Presentation aliases only: original IDs, request text and search words stay.
String _actionLabel(MoolAssistantAction action) =>
    const <String, String>{
      'Add a product to my Store': 'Add product',
      "Edit a product's details": 'Edit product details',
      'Add or edit product variants and packs': 'Edit variants and packs',
      'Add or change product photos': 'Change product photos',
      "Update a product's sale prices": 'Update sale prices',
      'Show my applications and Workspaces': 'View applications and Workspaces',
      'Continue a Workspace application': 'Continue Workspace application',
      'Choose the Workspace I want to apply for': 'Choose Workspace type',
      'Prepare my Workspace application details':
          'Prepare Workspace application',
      'Review and submit my Workspace application':
          'Review and submit application',
      'Check my application status': 'Check application status',
      'Correct a returned application': 'Correct returned application',
      'Open one of my approved Workspaces': 'Open approved Workspace',
      'Record a supplier purchase bill': 'Record purchase bill',
      'Record an advance paid to a supplier': 'Record supplier advance',
      'Record an on-account supplier payment':
          'Record on-account supplier payment',
      'Apply a payment or credit to a bill': 'Apply payment or credit to bill',
      'Record batch, pack and printed dates':
          'Enter batch, pack and printed dates',
      'Record a shortage or damaged delivery': 'Record shortage or damage',
      'Change quantities in my cart': 'Change Cart quantities',
      'Show my saved products': 'View saved products',
      'Show my orders': 'View orders',
      'Track my order': 'Track order',
      'View my order invoice': 'View order invoice',
    }[action.label] ??
    action.label;

String _actionCategory(MoolAssistantAction action) {
  if (action.group == 'Offers, finance and reports') {
    if (action.label.toLowerCase().contains('coupon')) return 'Coupons';
    if (action.label.toLowerCase().contains('finance')) return 'Finance';
    return 'Reports';
  }
  return switch (action.group) {
    'Shopping' => 'Buy',
    'Work' => 'Workspace setup',
    'Stock and receiving' => 'Stock',
    'Purchases and supplier accounts' => 'Purchases',
    'Orders and fulfilment' => 'Orders',
    'Sales and customers' => 'Sales',
    'Store settings' => 'Settings',
    _ => action.group,
  };
}

// User-facing task IDs, frozen per Buy/Store catalogue; never filtered-row positions.
// Existing domain IDs stay internal. Extend this mapping explicitly with future task amendments.
const _taskDisplayNumbers = <String, int>{
  'AI-ACT-025': 1,
  'AI-ACT-030': 2,
  'AI-ACT-032': 3,
  'AI-ACT-014': 4,
  'AI-ACT-021': 5,
  'AI-ACT-341': 6,
  'AI-ACT-002': 7,
  'AI-ACT-046': 8,
  'AI-ACT-017': 9,
  'AI-ACT-344': 10,
  'AI-ACT-018': 11,
  'AI-ACT-005': 12,
  'AI-ACT-047': 13,
  'AI-ACT-352': 14,
  'AI-ACT-041': 15,
  'AI-ACT-024': 16,
  'AI-ACT-007': 17,
  'AI-ACT-343': 18,
  'AI-ACT-033': 19,
  'AI-ACT-023': 20,
  'AI-ACT-028': 21,
  'AI-ACT-011': 22,
  'AI-ACT-013': 23,
  'AI-ACT-012': 24,
  'AI-ACT-020': 25,
  'AI-ACT-008': 26,
  'AI-ACT-053': 27,
  'AI-ACT-339': 28,
  'AI-ACT-040': 29,
  'AI-ACT-345': 30,
  'AI-ACT-336': 31,
  'AI-ACT-414': 32,
  'AI-ACT-026': 33,
  'AI-ACT-035': 34,
  'AI-ACT-003': 35,
  'AI-ACT-001': 36,
  'AI-ACT-338': 37,
  'AI-ACT-004': 38,
  'AI-ACT-052': 39,
  'AI-ACT-029': 40,
  'AI-ACT-350': 41,
  'AI-ACT-016': 42,
  'AI-ACT-055': 43,
  'AI-ACT-059': 44,
  'AI-ACT-042': 45,
  'AI-ACT-058': 46,
  'AI-ACT-057': 47,
  'AI-ACT-347': 48,
  'AI-ACT-027': 49,
  'AI-ACT-019': 50,
  'AI-ACT-348': 51,
  'AI-ACT-022': 52,
  'AI-ACT-346': 53,
  'AI-ACT-056': 54,
  'AI-ACT-051': 55,
  'AI-ACT-050': 56,
  'AI-ACT-048': 57,
  'AI-ACT-340': 58,
  'AI-ACT-060': 59,
  'AI-ACT-351': 60,
  'AI-ACT-049': 61,
  'AI-ACT-349': 62,
  'AI-ACT-037': 63,
  'AI-ACT-039': 64,
  'AI-ACT-038': 65,
  'AI-ACT-009': 66,
  'AI-ACT-015': 67,
  'AI-ACT-031': 68,
  'AI-ACT-342': 69,
  'AI-ACT-337': 70,
  'AI-ACT-034': 71,
  'AI-ACT-006': 72,
  'AI-ACT-045': 73,
  'AI-ACT-044': 74,
  'AI-ACT-413': 75,
  'AI-ACT-043': 76,
  'AI-ACT-010': 77,
  'AI-ACT-054': 78,
  'AI-ACT-275': 1,
  'AI-ACT-235': 2,
  'AI-ACT-402': 3,
  'AI-ACT-403': 4,
  'AI-ACT-289': 5,
  'AI-ACT-239': 6,
  'AI-ACT-369': 7,
  'AI-ACT-213': 8,
  'AI-ACT-233': 9,
  'AI-ACT-281': 10,
  'AI-ACT-305': 11,
  'AI-ACT-262': 12,
  'AI-ACT-285': 13,
  'AI-ACT-219': 14,
  'AI-ACT-323': 15,
  'AI-ACT-216': 16,
  'AI-ACT-327': 17,
  'AI-ACT-318': 18,
  'AI-ACT-322': 19,
  'AI-ACT-319': 20,
  'AI-ACT-326': 21,
  'AI-ACT-324': 22,
  'AI-ACT-300': 23,
  'AI-ACT-304': 24,
  'AI-ACT-399': 25,
  'AI-ACT-263': 26,
  'AI-ACT-225': 27,
  'AI-ACT-265': 28,
  'AI-ACT-302': 29,
  'AI-ACT-249': 30,
  'AI-ACT-250': 31,
  'AI-ACT-267': 32,
  'AI-ACT-374': 33,
  'AI-ACT-373': 34,
  'AI-ACT-316': 35,
  'AI-ACT-284': 36,
  'AI-ACT-231': 37,
  'AI-ACT-279': 38,
  'AI-ACT-398': 39,
  'AI-ACT-313': 40,
  'AI-ACT-240': 41,
  'AI-ACT-401': 42,
  'AI-ACT-371': 43,
  'AI-ACT-256': 44,
  'AI-ACT-220': 45,
  'AI-ACT-282': 46,
  'AI-ACT-283': 47,
  'AI-ACT-258': 48,
  'AI-ACT-244': 49,
  'AI-ACT-243': 50,
  'AI-ACT-381': 51,
  'AI-ACT-309': 52,
  'AI-ACT-292': 53,
  'AI-ACT-328': 54,
  'AI-ACT-255': 55,
  'AI-ACT-410': 56,
  'AI-ACT-408': 57,
  'AI-ACT-314': 58,
  'AI-ACT-370': 59,
  'AI-ACT-237': 60,
  'AI-ACT-214': 61,
  'AI-ACT-320': 62,
  'AI-ACT-215': 63,
  'AI-ACT-246': 64,
  'AI-ACT-296': 65,
  'AI-ACT-229': 66,
  'AI-ACT-253': 67,
  'AI-ACT-236': 68,
  'AI-ACT-372': 69,
  'AI-ACT-273': 70,
  'AI-ACT-228': 71,
  'AI-ACT-245': 72,
  'AI-ACT-222': 73,
  'AI-ACT-400': 74,
  'AI-ACT-390': 75,
  'AI-ACT-269': 76,
  'AI-ACT-411': 77,
  'AI-ACT-226': 78,
  'AI-ACT-238': 79,
  'AI-ACT-287': 80,
  'AI-ACT-277': 81,
  'AI-ACT-394': 82,
  'AI-ACT-230': 83,
  'AI-ACT-384': 84,
  'AI-ACT-407': 85,
  'AI-ACT-409': 86,
  'AI-ACT-310': 87,
  'AI-ACT-321': 88,
  'AI-ACT-303': 89,
  'AI-ACT-301': 90,
  'AI-ACT-270': 91,
  'AI-ACT-271': 92,
  'AI-ACT-376': 93,
  'AI-ACT-375': 94,
  'AI-ACT-264': 95,
  'AI-ACT-259': 96,
  'AI-ACT-266': 97,
  'AI-ACT-247': 98,
  'AI-ACT-299': 99,
  'AI-ACT-261': 100,
  'AI-ACT-280': 101,
  'AI-ACT-252': 102,
  'AI-ACT-248': 103,
  'AI-ACT-260': 104,
  'AI-ACT-257': 105,
  'AI-ACT-298': 106,
  'AI-ACT-386': 107,
  'AI-ACT-286': 108,
  'AI-ACT-377': 109,
  'AI-ACT-379': 110,
  'AI-ACT-378': 111,
  'AI-ACT-380': 112,
  'AI-ACT-251': 113,
  'AI-ACT-396': 114,
  'AI-ACT-388': 115,
  'AI-ACT-311': 116,
  'AI-ACT-276': 117,
  'AI-ACT-234': 118,
  'AI-ACT-227': 119,
  'AI-ACT-307': 120,
  'AI-ACT-391': 121,
  'AI-ACT-291': 122,
  'AI-ACT-242': 123,
  'AI-ACT-404': 124,
  'AI-ACT-406': 125,
  'AI-ACT-241': 126,
  'AI-ACT-385': 127,
  'AI-ACT-382': 128,
  'AI-ACT-278': 129,
  'AI-ACT-290': 130,
  'AI-ACT-295': 131,
  'AI-ACT-383': 132,
  'AI-ACT-412': 133,
  'AI-ACT-395': 134,
  'AI-ACT-315': 135,
  'AI-ACT-274': 136,
  'AI-ACT-312': 137,
  'AI-ACT-232': 138,
  'AI-ACT-288': 139,
  'AI-ACT-223': 140,
  'AI-ACT-224': 141,
  'AI-ACT-317': 142,
  'AI-ACT-272': 143,
  'AI-ACT-221': 144,
  'AI-ACT-217': 145,
  'AI-ACT-393': 146,
  'AI-ACT-293': 147,
  'AI-ACT-294': 148,
  'AI-ACT-254': 149,
  'AI-ACT-268': 150,
  'AI-ACT-397': 151,
  'AI-ACT-297': 152,
  'AI-ACT-218': 153,
  'AI-ACT-387': 154,
  'AI-ACT-308': 155,
  'AI-ACT-389': 156,
  'AI-ACT-405': 157,
  'AI-ACT-392': 158,
};

int _taskNumber(MoolAssistantAction action) => _taskDisplayNumbers[action.id]!;

class _AssistantActions extends StatelessWidget {
  const _AssistantActions({required this.controller, required this.query, required this.onSelected});
  final MoolAssistantController controller;
  final String query;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = query.trim().toLowerCase();
    final numeric = RegExp(r'^(?:#|task\s*)?(\d+)$').firstMatch(text);
    final number = numeric == null ? null : int.tryParse(numeric.group(1)!);
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final all = controller.actions();
    final actions = all.where((a) => numeric != null
      ? _taskNumber(a) == number
      : words.every((w) => '${a.label} ${_actionLabel(a)} ${_actionCategory(a)}'.toLowerCase().contains(w))).toList()
      ..sort((a, b) {
        final order = _actionLabel(a).toLowerCase().compareTo(_actionLabel(b).toLowerCase());
        return order != 0 ? order : _taskNumber(a).compareTo(_taskNumber(b));
      });
    if (actions.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(
        all.isEmpty ? 'Tasks are unavailable right now.' : 'No matching tasks. Try another word.')));
    }
    const example = 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 4, 16, 6),
        child: Text('Tap a task, or type "Do task $example" in the chat.',
          key: const Key('mool-assistant-task-number-hint'),
          style: const TextStyle(fontSize: 12, color: _AssistantColors.muted))),
      Expanded(child: ListView.separated(
        key: const Key('mool-assistant-action-list'),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        separatorBuilder: (_, index) => Divider(
          key: ValueKey('assistant-task-separator-$index'),
          height: 1, thickness: .5, indent: 40, endIndent: 4,
          color: MoolColors.line.withValues(alpha: .45)),
        itemBuilder: (context, i) {
          final action = actions[i];
          return ListTile(
            key: ValueKey('assistant-action-${action.id}'),
            dense: true,
            enableFeedback: false,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            selectedTileColor: const Color(0xFFD8E5FF),
            hoverColor: const Color(0xFFE4EDFF),
            focusColor: const Color(0xFFD5E3FD),
            minTileHeight: 48,
            minVerticalPadding: 0,
            titleAlignment: ListTileTitleAlignment.center,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            minLeadingWidth: 28,
            horizontalTitleGap: 8,
            leading: Text('${_taskNumber(action)}',
              key: ValueKey('assistant-task-number-${action.id}'),
              style: const TextStyle(fontSize: 12, color: _AssistantColors.muted)),
            title: Text(_actionLabel(action), style: const TextStyle(fontSize: 14)),
            onTap: controller.canChangeConversation ? () => onSelected(action.id) : null,
          );
        },
      )),
    ]);
  }
}

class _AssistantPanelBody extends StatelessWidget {
  const _AssistantPanelBody({required this.header, required this.body});
  final Widget header, body;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, layout) => SingleChildScrollView(
      child: SizedBox(
        height: math.max(
          layout.maxHeight,
          220 * MediaQuery.textScalerOf(context).scale(1),
        ),
        child: Column(
          children: [
            header,
            Expanded(child: body),
          ],
        ),
      ),
    ),
  );
}

class _AssistantHistory extends StatefulWidget {
  const _AssistantHistory({required this.controller});
  final MoolAssistantController controller;
  @override
  State<_AssistantHistory> createState() => _AssistantHistoryState();
}

class _AssistantHistoryState extends State<_AssistantHistory> {
  final _search = TextEditingController();
  late final Object _binding;
  late final int _epoch;
  String _query = '';
  bool get _current =>
      _binding == widget.controller.context.binding &&
      _epoch == widget.controller.epoch;
  bool get _canSearch => mounted && _current && widget.controller.historySource != null;

  @override
  void initState() {
    super.initState();
    _binding = widget.controller.context.binding;
    _epoch = widget.controller.epoch;
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    if (!_canSearch) {
      _query = '';
      _search.clear();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _search.dispose();
    super.dispose();
  }

  String _group(DateTime timestamp, DateTime today) {
    final local = timestamp.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return 'Today';
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return 'Yesterday';
    }
    return day.isAfter(today) ? 'Other dates' : 'Older';
  }

  void _open(MoolAssistantConversation row) {
    final c = widget.controller;
    c.synchronize();
    if (mounted && _binding == c.context.binding && _epoch == c.epoch) {
      Navigator.pop(context, row.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, current = _current;
    final loaded = current
        ? List<MoolAssistantConversation>.of(c.history)
        : <MoolAssistantConversation>[];
    final order = List<int>.generate(loaded.length, (i) => i)
      ..sort((a, b) {
        final byDate = loaded[b].updatedAt.compareTo(loaded[a].updatedAt);
        return byDate != 0 ? byDate : a.compareTo(b);
      });
    final query = _canSearch ? _query.trim().toLowerCase() : '';
    final matches = [
      for (final i in order)
        if (query.isEmpty || loaded[i].title.toLowerCase().contains(query))
          loaded[i],
    ];
    final now = c.presentationTime, items = <Object>[];
    final today = DateTime(now.year, now.month, now.day);
    String? previous;
    for (final row in matches) {
      final group = _group(row.updatedAt, today);
      if (group != previous) {
        items.add(group);
        previous = group;
      }
      items.add(row);
    }
    final notice = current ? c.historyNotice : null;
    final more = current && c.historyCursor != null;
    final partial = _canSearch && (c.historyLoading || more || notice != null);
    return _AssistantPanelBody(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Close history',
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              visualDensity: VisualDensity.standard,
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!current)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Your account or Store changed. Reopen History.'),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('mool-assistant-history-search'),
              controller: _search,
              enabled: _canSearch,
              maxLines: 1,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                if (_canSearch) setState(() => _query = value);
              },
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: partial ? 'Search loaded chats' : 'Search chats',
                prefixIcon: const Icon(Icons.search, key: Key('mool-assistant-history-search-icon'), size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 48,
                ),
                suffixIcon: _query.isNotEmpty && _canSearch ? IconButton(
                  tooltip: 'Clear chat search',
                  onPressed: () {
                    if (!_canSearch) return;
                    setState(() { _query = ''; _search.clear(); });
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                ) : null,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                constraints: const BoxConstraints(minHeight: 48),
              ),
            ),
          ),
          if (notice != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                notice,
                style: const TextStyle(fontSize: 13, color: _AssistantColors.muted),
              ),
            ),
          if (current && c.historyLoading) const LinearProgressIndicator(),
          if (current &&
              c.historySource != null &&
              notice != null &&
              !c.historyLoading)
            TextButton(
              onPressed: () => c.loadHistory(),
              child: const Text('Try again'),
            ),
          if (current &&
              query.isNotEmpty &&
              matches.isEmpty &&
              !c.historyLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No matching chats'),
            ),
          if (current &&
              query.isEmpty &&
              loaded.isEmpty &&
              notice == null &&
              !c.historyLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No saved chats yet.'),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length + (more ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return TextButton(
                    onPressed: c.historyLoading
                        ? null
                        : () => c.loadHistory(more: true),
                    child: const Text('Load more chats'),
                  );
                }
                final item = items[index];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _AssistantColors.muted,
                      ),
                    ),
                  );
                }
                final row = item as MoolAssistantConversation,
                    date = row.updatedAt.toLocal();
                final caption = c.context.inWorkspace
                    ? 'Store · ${c.context.workspaceName ?? 'Store'}'
                    : 'Buy';
                return ListTile(
                  key: ValueKey('assistant-history-${row.id}'),
                  dense: true,
                  minTileHeight: 48,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    row.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '$caption · ${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _AssistantColors.muted,
                    ),
                  ),
                  onTap: () => _open(row),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _assistantDialog(
  BuildContext context, {
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  bool scrollable = true,
}) {
  final theme = _assistantTheme(context);
  return Theme(
    data: theme.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    ),
    child: AlertDialog(
      scrollable: scrollable,
      title: title,
      content: content,
      actions: actions,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: _AssistantColors.muted,
        height: 1.4,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

/// Shared visual only. THIN-F02 binds it to typed, current native handoffs.
/// Compact partial preparation feedback; choosing an item does not execute it.
class MoolAssistantPreparationCard extends StatelessWidget {
  const MoolAssistantPreparationCard({super.key,required this.controller,required this.batch});
  final MoolAssistantController controller;
  final MoolAssistantPreparationBatch batch;
  @override Widget build(BuildContext context)=>Row(key:const Key('mool-assistant-preparation-batch'),children:[
    const Expanded(child:Text('Prepared tasks',style:TextStyle(fontSize:14,fontWeight:FontWeight.w600))),
    IconButton(tooltip:'Dismiss prepared tasks',onPressed:controller.cancelProposal,icon:const Icon(Icons.close,size:20)),
  ]);
}

/// One existing result-list child, built only near the visible viewport.
class MoolAssistantPreparationRow extends StatelessWidget {
  const MoolAssistantPreparationRow({super.key,required this.controller,required this.item});
  final MoolAssistantController controller;
  final MoolAssistantPreparationItem item;
  @override Widget build(BuildContext context)=>ListTile(contentPadding:EdgeInsets.zero,
    title:Text(item.title,style:const TextStyle(fontSize:14)),
    subtitle:Text('${switch(item.state){MoolAssistantPreparationState.ready=>controller.preparationItemSelected(item.id)?'Selected for review':'Ready to review',MoolAssistantPreparationState.needsInput=>'More details needed',MoolAssistantPreparationState.unavailable=>'Unavailable'}} · ${item.detail}',style:const TextStyle(fontSize:12)),
    trailing:item.state==MoolAssistantPreparationState.ready && !controller.preparationItemSelected(item.id)
      ?TextButton(onPressed:controller.canChangeConversation && controller.proposal==null
        ?()=>controller.choosePreparationItem(item.id):null,child:const Text('Choose')):null);
}

/// There is deliberately no fabricated proposal in the runtime empty state.
class MoolAssistantProposalCard extends StatelessWidget {
  const MoolAssistantProposalCard({
    required this.title,
    required this.summary,
    required this.onReview,
    required this.onCancel,
    this.busy = false,
    super.key,
  });

  final String title;
  final String summary;
  final VoidCallback? onReview;
  final VoidCallback onCancel;
  final bool busy;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 4,
    shadowColor: const Color(0x18000000),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF9BB3D7))),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: _AssistantColors.accent)),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: _AssistantColors.muted,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
                onPressed: onReview,
                child: Text(busy ? 'Opening…' : 'Review'),
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
