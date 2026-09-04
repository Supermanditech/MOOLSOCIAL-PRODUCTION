import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../chat_entry_context.dart';
import '../chat_models.dart';
import '../chat_session.dart';
import '../widgets/chat_motion.dart';
import '../widgets/chat_widgets.dart';

enum _SharedContentFilter { all, media, files, links }

class ChatSharedContentScreen extends StatefulWidget {
  const ChatSharedContentScreen({
    required this.session,
    required this.threadId,
    required this.originReturnRoute,
    super.key,
  });

  final ChatSession session;
  final String threadId;
  final String originReturnRoute;

  @override
  State<ChatSharedContentScreen> createState() =>
      _ChatSharedContentScreenState();
}

class _ChatSharedContentScreenState extends State<ChatSharedContentScreen> {
  _SharedContentFilter _filter = _SharedContentFilter.all;

  List<_SharedContentItem> _items() {
    final items = <_SharedContentItem>[];
    for (final message in widget.session.messages(widget.threadId)) {
      if (message.photo case final photo?) {
        items.add(_SharedContentItem.photo(message, photo));
      }
      if (message.attachmentLabel case final attachment?) {
        items.add(_SharedContentItem.file(message, attachment));
      }
      if (message.attachment case final attachment?) {
        items.add(_SharedContentItem.attachment(message, attachment));
      }
      for (final url in _messageUrls(message.text)) {
        items.add(_SharedContentItem.link(message, url));
      }
    }
    return items
        .where((item) {
          return switch (_filter) {
            _SharedContentFilter.all => true,
            _SharedContentFilter.media =>
              item.kind == _SharedContentKind.photo ||
                  item.kind == _SharedContentKind.video ||
                  item.kind == _SharedContentKind.voice,
            _SharedContentFilter.files => item.kind == _SharedContentKind.file,
            _SharedContentFilter.links => item.kind == _SharedContentKind.link,
          };
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.session.thread(widget.threadId);
    final entryContext = ChatEntryContext.resolve(widget.originReturnRoute);
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final items = _items();
        return ChatPageScaffold(
          key: const Key('chat-shared-content-screen'),
          session: widget.session,
          title: 'Media, files and links',
          subtitle: thread.title,
          returnRoute: chatRoute(
            '/app/chat/thread/${thread.id}',
            returnRoute: widget.originReturnRoute,
          ),
          showContentBack: true,
          backKeyName: 'chat-shared-content-back',
          titleIcon: Icons.perm_media_outlined,
          titleAccent: entryContext.accent,
          showMessageBanner: false,
          backgroundColor: const Color(0xFFF4F5F8),
          body: Column(
            children: [
              Material(
                color: Colors.white,
                child: SizedBox(
                  height: 58,
                  child: ListView.separated(
                    key: const Key('chat-shared-content-filters'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _SharedContentFilter.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final value = _SharedContentFilter.values[index];
                      return ChoiceChip(
                        key: Key('chat-shared-filter-${value.name}'),
                        label: Text(_filterLabel(value)),
                        selected: _filter == value,
                        onSelected: (_) => setState(() => _filter = value),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? ChatFiniteIncomingMotion(
                        stateKey: 'shared-content-empty-${_filter.name}',
                        child: _SharedContentEmpty(filter: _filter),
                      )
                    : ListView.separated(
                        key: const Key('chat-shared-content-list'),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) => ChatListEntryMotion(
                          stateKey: items[index].keyName,
                          index: index,
                          child: _SharedContentCard(
                            item: items[index],
                            onTap: () =>
                                unawaited(_openItem(context, items[index])),
                          ),
                        ),
                      ),
              ),
              const SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 5, 16, 10),
                  child: Text(
                    'Shows content currently loaded in this conversation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MoolColors.muted, fontSize: 11.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openItem(BuildContext context, _SharedContentItem item) async {
    switch (item.kind) {
      case _SharedContentKind.photo:
        await _showPhotoPreview(context, item);
      case _SharedContentKind.file:
        if (item.attachment case final attachment?) {
          final opened = await widget.session.openAttachment(
            widget.threadId,
            attachment,
          );
          if (!opened && context.mounted) {
            await showChatUnavailableCapability(
              context,
              keyName: 'chat-shared-file-recovery',
              title: 'File opening unavailable',
              message:
                  widget.session.threadActionError(widget.threadId) ??
                  'This file cannot be opened right now. Nothing changed.',
            );
          }
        } else {
          await showChatUnavailableCapability(
            context,
            keyName: 'chat-shared-file-recovery',
            title: 'File opening unavailable',
            message:
                'This loaded message contains a file reference, but the file cannot be opened right now. Nothing changed.',
          );
        }
      case _SharedContentKind.video || _SharedContentKind.voice:
        final opened = await widget.session.openAttachment(
          widget.threadId,
          item.attachment!,
        );
        if (!opened && context.mounted) {
          await showChatUnavailableCapability(
            context,
            keyName: 'chat-shared-media-recovery',
            title: 'Media opening unavailable',
            message:
                widget.session.threadActionError(widget.threadId) ??
                'This media cannot be opened right now.',
          );
        }
      case _SharedContentKind.link:
        await _showLinkDetails(context, item.value);
    }
  }
}

class _SharedContentCard extends StatelessWidget {
  const _SharedContentCard({required this.item, required this.onTap});

  final _SharedContentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: MoolColors.line.withValues(alpha: .7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: Key('chat-shared-item-${item.keyName}'),
        minTileHeight: 68,
        leading: CircleAvatar(
          backgroundColor: MoolColors.navy.withValues(alpha: .08),
          child: Icon(item.icon, color: MoolColors.navy),
        ),
        title: Text(
          item.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${item.message.sender} · ${item.message.timeLabel}'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _SharedContentEmpty extends StatelessWidget {
  const _SharedContentEmpty({required this.filter});

  final _SharedContentFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 46, color: MoolColors.muted),
            const SizedBox(height: 10),
            Text(
              'No ${_filterLabel(filter).toLowerCase()} here yet',
              key: const Key('chat-shared-content-empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'New loaded conversation content will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MoolColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SharedContentKind { photo, video, voice, file, link }

class _SharedContentItem {
  const _SharedContentItem._({
    required this.kind,
    required this.message,
    required this.value,
    required this.keyName,
    required this.icon,
    this.photo,
    this.attachment,
  });

  factory _SharedContentItem.photo(
    ChatMessage message,
    ChatPhotoAttachment photo,
  ) => _SharedContentItem._(
    kind: _SharedContentKind.photo,
    message: message,
    value: photo.name,
    keyName: 'photo-${message.id}',
    icon: Icons.photo_outlined,
    photo: photo,
  );

  factory _SharedContentItem.file(ChatMessage message, String value) =>
      _SharedContentItem._(
        kind: _SharedContentKind.file,
        message: message,
        value: value,
        keyName: 'file-${message.id}',
        icon: Icons.description_outlined,
      );

  factory _SharedContentItem.attachment(
    ChatMessage message,
    ChatAttachment attachment,
  ) => _SharedContentItem._(
    kind: switch (attachment.kind) {
      ChatAttachmentKind.document => _SharedContentKind.file,
      ChatAttachmentKind.video => _SharedContentKind.video,
      ChatAttachmentKind.voice => _SharedContentKind.voice,
    },
    message: message,
    value: attachment.kind == ChatAttachmentKind.voice
        ? 'Voice message'
        : attachment.name,
    keyName: 'attachment-${message.id}',
    icon: switch (attachment.kind) {
      ChatAttachmentKind.document => Icons.description_outlined,
      ChatAttachmentKind.video => Icons.video_file_outlined,
      ChatAttachmentKind.voice => Icons.graphic_eq_rounded,
    },
    attachment: attachment,
  );

  factory _SharedContentItem.link(ChatMessage message, String value) =>
      _SharedContentItem._(
        kind: _SharedContentKind.link,
        message: message,
        value: value,
        keyName: 'link-${message.id}-${value.hashCode}',
        icon: Icons.link_rounded,
      );

  final _SharedContentKind kind;
  final ChatMessage message;
  final String value;
  final String keyName;
  final IconData icon;
  final ChatPhotoAttachment? photo;
  final ChatAttachment? attachment;
}

Future<void> _showPhotoPreview(BuildContext context, _SharedContentItem item) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    sheetAnimationStyle: ChatMotion.sheetStyle(context),
    builder: (sheetContext) => Padding(
      key: const Key('chat-shared-photo-preview'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.value,
            style: const TextStyle(
              color: MoolColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item.photo!.readUrl.toString(),
              height: 280,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 180,
                child: Center(child: Text('Photo preview unavailable.')),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('chat-shared-photo-close'),
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Continue in Chat'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showLinkDetails(BuildContext context, String value) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    sheetAnimationStyle: ChatMotion.sheetStyle(context),
    builder: (sheetContext) => Padding(
      key: const Key('chat-shared-link-details'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Shared link',
            style: TextStyle(
              color: MoolColors.navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(value),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('chat-shared-link-copy'),
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: value));
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              } on Object {
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                await Future<void>.delayed(Duration.zero);
                if (context.mounted) {
                  await showChatUnavailableCapability(
                    context,
                    keyName: 'chat-shared-link-copy-recovery',
                    title: 'Copy unavailable',
                    message: 'This link could not be copied right now.',
                  );
                }
              }
            },
            icon: const Icon(Icons.content_copy_rounded),
            label: const Text('Copy link'),
          ),
        ],
      ),
    ),
  );
}

List<String> _messageUrls(String text) {
  final matches = RegExp(
    r'https?://[^\s]+',
    caseSensitive: false,
  ).allMatches(text);
  return matches
      .map((match) => match.group(0)!)
      .map((value) => value.replaceFirst(RegExp(r'[.,!?;:)]+$'), ''))
      .where((value) => Uri.tryParse(value)?.hasAuthority ?? false)
      .toList(growable: false);
}

String _filterLabel(_SharedContentFilter value) => switch (value) {
  _SharedContentFilter.all => 'All',
  _SharedContentFilter.media => 'Media',
  _SharedContentFilter.files => 'Files',
  _SharedContentFilter.links => 'Links',
};
