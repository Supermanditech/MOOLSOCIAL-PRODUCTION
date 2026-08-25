import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_design.dart';
import 'buy_v2_shop_chat_motion.dart';

enum BuyV2ShopChatFilter { all, orders, sellers, offers }

@immutable
class BuyV2ShopChatFilterSpec {
  const BuyV2ShopChatFilterSpec({
    required this.id,
    required this.label,
    required this.sectionLabel,
    this.allLimit,
  });

  final String id;
  final String label;
  final String sectionLabel;
  final int? allLimit;
}

@immutable
class BuyV2ShopChatPresentation {
  const BuyV2ShopChatPresentation({
    required this.familyId,
    required this.familyLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.securityMessage,
    required this.newConversationPrompt,
    required this.filters,
  });

  static const shop = BuyV2ShopChatPresentation(
    familyId: 'shop',
    familyLabel: 'Shop',
    title: 'Shop Chat',
    subtitle: 'partners, orders and offers',
    icon: Icons.storefront_outlined,
    accent: BuyV2Colors.navy,
    securityMessage:
        'Shop conversations stay with your purchase in MoolSocial Chat.',
    newConversationPrompt: 'Choose who can help with this purchase.',
    filters: [
      BuyV2ShopChatFilterSpec(
        id: 'all',
        label: 'All',
        sectionLabel: 'Start with Shop',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'orders',
        label: 'Orders',
        sectionLabel: 'Order conversations',
        allLimit: 2,
      ),
      BuyV2ShopChatFilterSpec(
        id: 'sellers',
        label: 'Partners',
        sectionLabel: 'Partner conversations',
      ),
      BuyV2ShopChatFilterSpec(
        id: 'offers',
        label: 'Offers',
        sectionLabel: 'Offer conversations',
        allLimit: 1,
      ),
    ],
  );

  final String familyId;
  final String familyLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String securityMessage;
  final String newConversationPrompt;
  final List<BuyV2ShopChatFilterSpec> filters;

  BuyV2ShopChatFilterSpec filter(String id) => filters.firstWhere(
    (candidate) => candidate.id == id,
    orElse: () => filters.first,
  );
}

enum BuyV2ShopChatParticipantKind {
  retailer,
  wholesaler,
  manufacturer,
  orderSupport,
  offerSupport,
  restaurant,
  tableDesk,
  travelPartner,
  doctorDesk,
  medicineDesk,
  salonDesk,
  workOpportunity,
  workspaceSupport,
}

enum BuyV2ShopChatMessageKind {
  text,
  image,
  video,
  document,
  voice,
  product,
  order,
  location,
  contact,
}

enum BuyV2ShopChatDeliveryState { pending, sent, delivered, read, failed }

enum BuyV2ShopChatCommerceTarget { shop, wholesale, orders, offers }

enum BuyV2ShopChatActionKind {
  sendText,
  startVoiceCall,
  startVideoCall,
  captureImage,
  selectMedia,
  selectDocument,
  recordVoice,
  shareProduct,
  shareOrder,
  shareLocation,
  shareContact,
  openAttachment,
  reply,
  copyMessage,
  forwardMessage,
  reactToMessage,
  manageNotifications,
  openSafety,
}

enum BuyV2ShopChatActionDisposition { accepted, handedOff, unavailable }

@immutable
class BuyV2ShopChatCapabilities {
  const BuyV2ShopChatCapabilities({
    this.voiceCall = true,
    this.videoCall = true,
    this.camera = true,
    this.media = true,
    this.documents = true,
    this.voiceMessages = true,
    this.productSharing = true,
    this.orderSharing = true,
    this.locationSharing = true,
    this.contactSharing = true,
  });

  final bool voiceCall;
  final bool videoCall;
  final bool camera;
  final bool media;
  final bool documents;
  final bool voiceMessages;
  final bool productSharing;
  final bool orderSharing;
  final bool locationSharing;
  final bool contactSharing;

  bool get canAttach =>
      camera ||
      media ||
      documents ||
      productSharing ||
      orderSharing ||
      locationSharing ||
      contactSharing;
}

@immutable
class BuyV2ShopChatMessage {
  const BuyV2ShopChatMessage({
    required this.id,
    required this.kind,
    required this.fromCurrentUser,
    required this.sentAtLabel,
    this.body,
    this.attachmentName,
    this.attachmentDetail,
    this.deliveryState = BuyV2ShopChatDeliveryState.delivered,
    this.replyToLabel,
    this.reaction,
  });

  final String id;
  final BuyV2ShopChatMessageKind kind;
  final bool fromCurrentUser;
  final String sentAtLabel;
  final String? body;
  final String? attachmentName;
  final String? attachmentDetail;
  final BuyV2ShopChatDeliveryState deliveryState;
  final String? replyToLabel;
  final String? reaction;
}

@immutable
class BuyV2ShopChatThread {
  const BuyV2ShopChatThread({
    required this.id,
    required this.filter,
    required this.participantKind,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.accent,
    this.commerceTarget,
    required this.contextTitle,
    required this.contextDetail,
    this.messages = const [],
    this.quickReplies = const [],
    this.capabilities = const BuyV2ShopChatCapabilities(),
    this.filterId,
    this.previewTimeLabel,
    this.unreadCount = 0,
  });

  final String id;
  final BuyV2ShopChatFilter filter;
  final BuyV2ShopChatParticipantKind participantKind;
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color accent;
  final BuyV2ShopChatCommerceTarget? commerceTarget;
  final String contextTitle;
  final String contextDetail;
  final List<BuyV2ShopChatMessage> messages;
  final List<String> quickReplies;
  final BuyV2ShopChatCapabilities capabilities;
  final String? filterId;
  final String? previewTimeLabel;
  final int unreadCount;

  String get resolvedFilterId => filterId ?? filter.name;
}

@immutable
class BuyV2ShopChatAction {
  const BuyV2ShopChatAction({
    required this.kind,
    required this.threadId,
    this.text,
    this.messageId,
    this.replyToMessageId,
  });

  final BuyV2ShopChatActionKind kind;
  final String threadId;
  final String? text;
  final String? messageId;
  final String? replyToMessageId;
}

@immutable
class BuyV2ShopChatActionResult {
  const BuyV2ShopChatActionResult._(this.disposition, this.customerMessage);

  const BuyV2ShopChatActionResult.accepted([String? customerMessage])
    : this._(BuyV2ShopChatActionDisposition.accepted, customerMessage);

  const BuyV2ShopChatActionResult.handedOff()
    : this._(BuyV2ShopChatActionDisposition.handedOff, null);

  const BuyV2ShopChatActionResult.unavailable(String customerMessage)
    : this._(BuyV2ShopChatActionDisposition.unavailable, customerMessage);

  final BuyV2ShopChatActionDisposition disposition;
  final String? customerMessage;
}

typedef BuyV2ShopChatActionHandler =
    Future<BuyV2ShopChatActionResult> Function(BuyV2ShopChatAction action);

abstract interface class BuyV2ShopChatProvisioningSource {
  List<BuyV2ShopChatThread> threads(BuyV2Session? session);
}

/// Presentation-only default. A later runtime owner can provide authoritative
/// participants and messages through [BuyV2ShopChatProvisioningSource]
/// without changing Shop Chat layout or interaction contracts.
class BuyV2SessionShopChatProvisioningSource
    implements BuyV2ShopChatProvisioningSource {
  const BuyV2SessionShopChatProvisioningSource();

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? session) {
    if (session == null) return const [];
    final orderThreads = session.orders
        .where(
          (order) =>
              order.destination == BuyV2Destination.shop ||
              order.destination == BuyV2Destination.wholesale,
        )
        .map(BuyV2ShopChatThreadFactory.fromOrder)
        .toList(growable: false);
    return [
      ...orderThreads,
      const BuyV2ShopChatThread(
        id: 'retail-partner',
        filter: BuyV2ShopChatFilter.sellers,
        participantKind: BuyV2ShopChatParticipantKind.retailer,
        title: 'Mool Retail Partner',
        subtitle: 'Products, stock and local delivery',
        detail: 'Open Shop support',
        icon: Icons.storefront_outlined,
        accent: BuyV2Colors.orange,
        commerceTarget: BuyV2ShopChatCommerceTarget.shop,
        contextTitle: 'Retail shopping',
        contextDetail: 'Products, availability and delivery support',
        quickReplies: ['Is this in stock?', 'When can it arrive?'],
      ),
      const BuyV2ShopChatThread(
        id: 'wholesale-partner',
        filter: BuyV2ShopChatFilter.sellers,
        participantKind: BuyV2ShopChatParticipantKind.wholesaler,
        title: 'Mool Trade Partner',
        subtitle: 'Packs, pricing and fulfilment',
        detail: 'Open wholesale support',
        icon: Icons.inventory_2_outlined,
        accent: BuyV2Colors.green,
        commerceTarget: BuyV2ShopChatCommerceTarget.wholesale,
        contextTitle: 'Wholesale buying',
        contextDetail: 'Pack sizes, trade pricing and fulfilment',
        quickReplies: ['Ask pack pricing', 'Check fulfilment'],
      ),
      const BuyV2ShopChatThread(
        id: 'manufacturer-partner',
        filter: BuyV2ShopChatFilter.sellers,
        participantKind: BuyV2ShopChatParticipantKind.manufacturer,
        title: 'Mool Manufacturer',
        subtitle: 'Catalogue, packs and supply enquiries',
        detail: 'Open manufacturer support',
        icon: Icons.factory_outlined,
        accent: BuyV2Colors.navy,
        commerceTarget: BuyV2ShopChatCommerceTarget.wholesale,
        contextTitle: 'Manufacturer supply',
        contextDetail: 'Catalogue, minimum quantities and supply',
        quickReplies: ['Ask minimum order', 'Request product details'],
      ),
      const BuyV2ShopChatThread(
        id: 'offer-details',
        filter: BuyV2ShopChatFilter.offers,
        participantKind: BuyV2ShopChatParticipantKind.offerSupport,
        title: 'Offer details',
        subtitle: 'Price, pack size and validity',
        detail: 'Continue in MoolSocial Chat',
        icon: Icons.local_offer_outlined,
        accent: BuyV2Colors.orange,
        commerceTarget: BuyV2ShopChatCommerceTarget.offers,
        contextTitle: 'Published offers',
        contextDetail: 'Price, eligibility, pack size and validity',
        quickReplies: ['Is this offer valid?', 'Check eligibility'],
      ),
      const BuyV2ShopChatThread(
        id: 'offer-checkout',
        filter: BuyV2ShopChatFilter.offers,
        participantKind: BuyV2ShopChatParticipantKind.offerSupport,
        title: 'Offer and checkout help',
        subtitle: 'Eligibility, cart and payment questions',
        detail: 'Continue in MoolSocial Chat',
        icon: Icons.shopping_bag_outlined,
        accent: BuyV2Colors.navy,
        commerceTarget: BuyV2ShopChatCommerceTarget.offers,
        contextTitle: 'Offer checkout',
        contextDetail: 'Eligibility, cart and payment support',
        quickReplies: ['Help with this offer', 'Ask about checkout'],
      ),
    ];
  }
}

abstract final class BuyV2ShopChatThreadFactory {
  static BuyV2ShopChatThread fromOrder(BuyV2Order order) {
    final delivered = order.status == BuyV2OrderStatus.delivered;
    return BuyV2ShopChatThread(
      id: 'order-${order.id}',
      filter: BuyV2ShopChatFilter.orders,
      participantKind: BuyV2ShopChatParticipantKind.orderSupport,
      title: 'Order ${order.id}',
      subtitle: '${order.partner} · ${order.status.customerLabel}',
      detail: order.promise,
      icon: delivered
          ? Icons.inventory_2_outlined
          : Icons.local_shipping_outlined,
      accent: delivered ? BuyV2Colors.green : BuyV2Colors.navy,
      commerceTarget: BuyV2ShopChatCommerceTarget.orders,
      contextTitle: 'Order ${order.id}',
      contextDetail: '${order.status.customerLabel} · ${order.promise}',
      quickReplies: const ['Where is my order?', 'Help with this order'],
    );
  }
}

enum _BuyV2ShopChatSurface { inbox, newConversation, thread, info }

class BuyV2ShopChatRetainedState {
  String? filterId;
  String inboxQuery = '';
  final Map<String, _BuyV2ShopChatThreadRetainedState> _threads = {};

  _BuyV2ShopChatThreadRetainedState _thread(String threadId) =>
      _threads.putIfAbsent(threadId, _BuyV2ShopChatThreadRetainedState.new);
}

class _BuyV2ShopChatThreadRetainedState {
  String draft = '';
  String messageQuery = '';
  String? replyMessageId;
  bool messageSearchOpen = false;
}

enum _BuyV2ShopChatThreadUtility {
  messageActions,
  conversationOptions,
  messageSearch,
  attachmentChoices,
  emojiChoices,
  reply,
}

@immutable
class _BuyV2ShopChatThreadHistoryEntry {
  const _BuyV2ShopChatThreadHistoryEntry({
    required this.utility,
    this.message,
    this.messageQuery,
  });

  final _BuyV2ShopChatThreadUtility utility;
  final BuyV2ShopChatMessage? message;
  final String? messageQuery;

  String get destination => switch (utility) {
    _BuyV2ShopChatThreadUtility.messageActions => 'message actions',
    _BuyV2ShopChatThreadUtility.conversationOptions => 'conversation options',
    _BuyV2ShopChatThreadUtility.messageSearch => 'message search',
    _BuyV2ShopChatThreadUtility.attachmentChoices => 'sharing options',
    _BuyV2ShopChatThreadUtility.emojiChoices => 'emoji choices',
    _BuyV2ShopChatThreadUtility.reply => 'message reply',
  };
}

@immutable
class _BuyV2ShopChatHistoryEntry {
  const _BuyV2ShopChatHistoryEntry({required this.surface, this.thread});

  final _BuyV2ShopChatSurface surface;
  final BuyV2ShopChatThread? thread;
}

class BuyV2ShopChatView extends StatefulWidget {
  const BuyV2ShopChatView({
    super.key,
    this.session,
    required this.originLabel,
    required this.onBack,
    required this.onOpenProductionChat,
    this.initialFilter = BuyV2ShopChatFilter.all,
    this.initialFilterId,
    this.presentation = BuyV2ShopChatPresentation.shop,
    this.provisioningSource = const BuyV2SessionShopChatProvisioningSource(),
    this.onAction,
    this.onOpenCommerce,
    this.onOpenThreadContext,
    this.retainedState,
  });

  final BuyV2Session? session;
  final String originLabel;
  final VoidCallback onBack;
  final VoidCallback onOpenProductionChat;
  final BuyV2ShopChatFilter initialFilter;
  final String? initialFilterId;
  final BuyV2ShopChatPresentation presentation;
  final BuyV2ShopChatProvisioningSource provisioningSource;
  final BuyV2ShopChatActionHandler? onAction;
  final ValueChanged<BuyV2ShopChatCommerceTarget>? onOpenCommerce;
  final ValueChanged<BuyV2ShopChatThread>? onOpenThreadContext;
  final BuyV2ShopChatRetainedState? retainedState;

  @override
  State<BuyV2ShopChatView> createState() => BuyV2ShopChatViewState();
}

class BuyV2ShopChatViewState extends State<BuyV2ShopChatView> {
  late final BuyV2ShopChatRetainedState _retainedState;
  late String _filterId;
  late final TextEditingController _searchController;
  _BuyV2ShopChatSurface _surface = _BuyV2ShopChatSurface.inbox;
  BuyV2ShopChatThread? _selectedThread;
  final GlobalKey<_ShopChatConversationViewState> _threadViewKey = GlobalKey();
  final List<_BuyV2ShopChatHistoryEntry> _forwardHistory = [];
  bool _surfaceForward = true;
  int _surfaceSequence = 0;

  @override
  void initState() {
    super.initState();
    _retainedState = widget.retainedState ?? BuyV2ShopChatRetainedState();
    final initialFilterId = widget.initialFilterId ?? widget.initialFilter.name;
    final retainedFilterId = _retainedState.filterId;
    _filterId =
        retainedFilterId != null &&
            widget.presentation.filters.any(
              (filter) => filter.id == retainedFilterId,
            )
        ? retainedFilterId
        : initialFilterId;
    _retainedState.filterId = _filterId;
    _searchController = TextEditingController(text: _retainedState.inboxQuery);
    _searchController.addListener(_retainInboxQuery);
  }

  bool handleBack({bool dismissComposerKeyboard = true}) {
    if (_surface == _BuyV2ShopChatSurface.thread &&
        (_threadViewKey.currentState?.handleBack(
              dismissComposerKeyboard: dismissComposerKeyboard,
            ) ??
            false)) {
      return true;
    }
    final target = switch (_surface) {
      _BuyV2ShopChatSurface.info => _BuyV2ShopChatSurface.thread,
      _BuyV2ShopChatSurface.thread ||
      _BuyV2ShopChatSurface.newConversation => _BuyV2ShopChatSurface.inbox,
      _BuyV2ShopChatSurface.inbox => null,
    };
    if (target == null) return false;
    HapticFeedback.selectionClick();
    setState(() {
      _forwardHistory.add(
        _BuyV2ShopChatHistoryEntry(surface: _surface, thread: _selectedThread),
      );
      _surface = target;
      _surfaceForward = false;
      _surfaceSequence += 1;
    });
    return true;
  }

  @override
  void didUpdateWidget(covariant BuyV2ShopChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter ||
        oldWidget.initialFilterId != widget.initialFilterId ||
        oldWidget.presentation != widget.presentation) {
      _filterId = widget.initialFilterId ?? widget.initialFilter.name;
      _retainedState.filterId = _filterId;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_retainInboxQuery);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationForward = _forwardHistory.isEmpty
        ? null
        : _ShopChatNavigationForwardBar(
            destination: _forwardDestination(_forwardHistory.last),
            onPressed: _showForwardHistory,
          );
    final surface = switch (_surface) {
      _BuyV2ShopChatSurface.inbox => _buildInbox(
        context,
        navigationForward: navigationForward,
      ),
      _BuyV2ShopChatSurface.newConversation => _ShopChatNewConversationView(
        entries: widget.provisioningSource.threads(widget.session),
        presentation: widget.presentation,
        navigationForward: navigationForward,
        onBack: () => handleBack(dismissComposerKeyboard: false),
        onSelected: _openThread,
        onOpenAll: widget.onOpenProductionChat,
      ),
      _BuyV2ShopChatSurface.thread => _ShopChatConversationView(
        key: _threadViewKey,
        thread: _selectedThread!,
        retainedState: _retainedState._thread(_selectedThread!.id),
        navigationForward: navigationForward,
        onBack: () => handleBack(dismissComposerKeyboard: false),
        onOpenInfo: _showInfo,
        onDispatch: _dispatch,
        onOpenContext: _openContextFor(_selectedThread!),
        presentation: widget.presentation,
      ),
      _BuyV2ShopChatSurface.info => _ShopChatInfoView(
        key: ValueKey('buy-shop-chat-info-${_selectedThread!.id}'),
        thread: _selectedThread!,
        navigationForward: navigationForward,
        onBack: () => handleBack(dismissComposerKeyboard: false),
        onDispatch: _dispatch,
        onOpenContext: _openContextFor(_selectedThread!),
        presentation: widget.presentation,
      ),
    };
    return BuyV2ShopChatSurfaceMotion(
      stateKey: '${_surface.name}|$_surfaceSequence',
      forward: _surfaceForward,
      child: surface,
    );
  }

  Widget _buildInbox(
    BuildContext context, {
    required Widget? navigationForward,
  }) {
    final entries = _visibleEntries();
    final query = _searchController.text.trim();
    final hasProvisionedEntries =
        entries.isNotEmpty ||
        widget.provisioningSource.threads(widget.session).isNotEmpty;
    return Semantics(
      key: const ValueKey('buy-shop-chat'),
      container: true,
      label: '${widget.presentation.title}. ${widget.presentation.subtitle}.',
      child: ColoredBox(
        color: const Color(0xFFF8F8FC),
        child: Column(
          children: [
            _ShopChatHeader(
              originLabel: widget.originLabel,
              presentation: widget.presentation,
              onBack: widget.onBack,
              onOpenAll: widget.onOpenProductionChat,
            ),
            ?navigationForward,
            _ShopChatSearch(
              originLabel: widget.originLabel,
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
            _ShopChatFilters(
              presentation: widget.presentation,
              selectedId: _filterId,
              onSelected: (value) {
                HapticFeedback.selectionClick();
                setState(() {
                  _filterId = value;
                  _retainedState.filterId = value;
                });
              },
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: BuyV2Colors.line),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: BuyV2ShopChatFilterMotion(
                      stateKey: '$_filterId|${_searchController.text.trim()}',
                      child: entries.isEmpty
                          ? _ShopChatEmptyState(
                              familyLabel: widget.presentation.familyLabel,
                              query: query,
                              filterLabel: _filterId == 'all'
                                  ? null
                                  : widget.presentation.filter(_filterId).label,
                              hasProvisionedEntries: hasProvisionedEntries,
                              onClearSearch: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              onShowAll: () => setState(() {
                                _filterId = 'all';
                                _retainedState.filterId = 'all';
                              }),
                              onChooseConversation: _showNewConversationPicker,
                              onOpenAll: widget.onOpenProductionChat,
                            )
                          : ListView.builder(
                              key: PageStorageKey<String>(
                                'buy-shop-chat-results-${widget.presentation.familyId}-$_filterId',
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                88,
                              ),
                              itemCount: entries.length + 2,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _ShopChatContextBanner(
                                    presentation: widget.presentation,
                                    filter: widget.presentation.filter(
                                      _filterId,
                                    ),
                                    conversationCount: entries.length,
                                  );
                                }
                                if (index == 1) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      14,
                                      4,
                                      6,
                                    ),
                                    child: Text(
                                      widget.presentation
                                          .filter(_filterId)
                                          .sectionLabel,
                                      style: context.buyEyebrow.copyWith(
                                        color: BuyV2Colors.ink,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                }
                                final entry = entries[index - 2];
                                return BuyV2ShopChatEntryMotion(
                                  index: index - 2,
                                  child: _ShopChatEntryTile(
                                    entry: entry,
                                    categoryLabel: widget.presentation
                                        .filter(entry.resolvedFilterId)
                                        .label,
                                    onTap: () => _openThread(entry),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Semantics(
                      label:
                          'Choose a ${widget.presentation.familyLabel} conversation',
                      button: true,
                      child: Tooltip(
                        message:
                            'Choose a ${widget.presentation.familyLabel} conversation',
                        child: FloatingActionButton(
                          key: const ValueKey('buy-shop-chat-new'),
                          heroTag: 'buy-shop-chat-new',
                          elevation: 5,
                          backgroundColor: BuyV2Colors.navy,
                          foregroundColor: Colors.white,
                          onPressed: _showNewConversationPicker,
                          child: const Icon(Icons.add_comment_outlined),
                        ),
                      ),
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

  Future<BuyV2ShopChatActionResult> _dispatch(
    BuyV2ShopChatAction action,
  ) async {
    final handler = widget.onAction;
    if (handler == null) {
      widget.onOpenProductionChat();
      return const BuyV2ShopChatActionResult.handedOff();
    }
    try {
      return await handler(action);
    } catch (_) {
      return BuyV2ShopChatActionResult.unavailable(
        action.kind.unexpectedFailureMessage,
      );
    }
  }

  VoidCallback? _openContextFor(BuyV2ShopChatThread thread) {
    final onOpenThreadContext = widget.onOpenThreadContext;
    if (onOpenThreadContext != null) {
      return () => onOpenThreadContext(thread);
    }
    final target = thread.commerceTarget;
    final onOpenCommerce = widget.onOpenCommerce;
    if (target == null || onOpenCommerce == null) return null;
    return () => onOpenCommerce(target);
  }

  void _openThread(BuyV2ShopChatThread thread) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _forwardHistory.clear();
      _selectedThread = thread;
      _surface = _BuyV2ShopChatSurface.thread;
      _surfaceForward = true;
      _surfaceSequence += 1;
    });
  }

  void _showInfo() {
    HapticFeedback.selectionClick();
    setState(() {
      _forwardHistory.clear();
      _surface = _BuyV2ShopChatSurface.info;
      _surfaceForward = true;
      _surfaceSequence += 1;
    });
  }

  void _showNewConversationPicker() {
    HapticFeedback.selectionClick();
    setState(() {
      _forwardHistory.clear();
      _surface = _BuyV2ShopChatSurface.newConversation;
      _surfaceForward = true;
      _surfaceSequence += 1;
    });
  }

  void _showForwardHistory() {
    if (_forwardHistory.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      final target = _forwardHistory.removeLast();
      _surface = target.surface;
      _selectedThread = target.thread ?? _selectedThread;
      _surfaceForward = true;
      _surfaceSequence += 1;
    });
  }

  void _retainInboxQuery() {
    _retainedState.inboxQuery = _searchController.text;
  }

  String _forwardDestination(_BuyV2ShopChatHistoryEntry entry) =>
      switch (entry.surface) {
        _BuyV2ShopChatSurface.inbox =>
          '${widget.presentation.familyLabel} conversations',
        _BuyV2ShopChatSurface.newConversation =>
          '${widget.presentation.familyLabel} conversation choices',
        _BuyV2ShopChatSurface.thread =>
          entry.thread?.title ?? '${widget.presentation.familyLabel} thread',
        _BuyV2ShopChatSurface.info =>
          '${entry.thread?.title ?? widget.presentation.familyLabel} info',
      };

  List<BuyV2ShopChatThread> _visibleEntries() {
    final allEntries = _entriesFor(_filterId);
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return allEntries;
    final tokens = query
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);
    return allEntries
        .where((entry) {
          final searchable = [
            entry.title,
            entry.subtitle,
            entry.detail,
            widget.presentation.filter(entry.resolvedFilterId).label,
          ].join(' ').toLowerCase();
          return tokens.every(searchable.contains);
        })
        .toList(growable: false);
  }

  List<BuyV2ShopChatThread> _entriesFor(String filterId) {
    final allEntries = widget.provisioningSource.threads(widget.session);
    if (filterId != 'all') {
      return allEntries
          .where((entry) => entry.resolvedFilterId == filterId)
          .toList(growable: false);
    }
    final visible = <BuyV2ShopChatThread>[];
    for (final filter in widget.presentation.filters) {
      if (filter.id == 'all') continue;
      final matching = allEntries.where(
        (entry) => entry.resolvedFilterId == filter.id,
      );
      visible.addAll(
        filter.allLimit == null ? matching : matching.take(filter.allLimit!),
      );
    }
    return visible;
  }
}

class _ShopChatHeader extends StatelessWidget {
  const _ShopChatHeader({
    required this.originLabel,
    required this.presentation,
    required this.onBack,
    required this.onOpenAll,
  });

  final String originLabel;
  final BuyV2ShopChatPresentation presentation;
  final VoidCallback onBack;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: BuyV2Colors.line)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            presentation.accent.withValues(alpha: .08),
            Colors.white,
            BuyV2Colors.softBlue.withValues(alpha: .36),
          ],
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('buy-shop-chat-back'),
              tooltip: 'Back to $originLabel',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: BuyV2Colors.ink,
            ),
            const SizedBox(width: 2),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: presentation.accent.withValues(alpha: .11),
                    border: Border.all(
                      color: presentation.accent.withValues(alpha: .22),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.accent,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [BuyV2Colors.navy, BuyV2Colors.royal],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presentation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyTitle.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$originLabel · ${presentation.subtitle}',
                    key: const ValueKey('buy-shop-chat-origin'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyMeta.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('buy-shop-chat-open-all'),
              tooltip: 'All MoolSocial chats',
              onPressed: onOpenAll,
              icon: const Icon(Icons.forum_outlined),
              color: BuyV2Colors.navy,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatNavigationForwardBar extends StatelessWidget {
  const _ShopChatNavigationForwardBar({
    required this.destination,
    required this.onPressed,
  });

  final String destination;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = 'Navigate forward to $destination';
    return Semantics(
      key: const ValueKey('buy-shop-chat-history-forward'),
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFFEFF3FF),
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Forward to $destination',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyMeta.copyWith(
                        color: BuyV2Colors.navy,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: BuyV2Colors.navy,
                    size: 18,
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

class _ShopChatSearch extends StatelessWidget {
  const _ShopChatSearch({
    required this.originLabel,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final String originLabel;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: SizedBox(
        height: 48,
        child: TextField(
          key: const ValueKey('buy-shop-chat-search'),
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: context.buyBody.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search $originLabel conversations',
            hintStyle: context.buyMeta.copyWith(fontSize: 12),
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    key: const ValueKey('buy-shop-chat-search-clear'),
                    tooltip: 'Clear Shop Chat search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BuyV2Colors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BuyV2Colors.navy, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopChatFilters extends StatelessWidget {
  const _ShopChatFilters({
    required this.presentation,
    required this.selectedId,
    required this.onSelected,
  });

  final BuyV2ShopChatPresentation presentation;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        key: const ValueKey('buy-shop-chat-filters'),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: presentation.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final filter = presentation.filters[index];
          final active = filter.id == selectedId;
          return Semantics(
            selected: active,
            button: true,
            label: '${filter.label} ${presentation.title} filter',
            child: ChoiceChip(
              key: ValueKey('buy-shop-chat-filter-${filter.id}'),
              label: Text(filter.label),
              selected: active,
              showCheckmark: false,
              onSelected: active ? null : (_) => onSelected(filter.id),
              labelStyle: TextStyle(
                color: active ? Colors.white : BuyV2Colors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              selectedColor: BuyV2Colors.navy,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: active ? BuyV2Colors.navy : BuyV2Colors.line,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
            ),
          );
        },
      ),
    );
  }
}

class _ShopChatContextBanner extends StatelessWidget {
  const _ShopChatContextBanner({
    required this.presentation,
    required this.filter,
    required this.conversationCount,
  });

  final BuyV2ShopChatPresentation presentation;
  final BuyV2ShopChatFilterSpec filter;
  final int conversationCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${filter.label} ${presentation.familyLabel} Chat context. ${presentation.securityMessage}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: buyV2CardDecoration(
          color: Colors.white,
          border: presentation.accent.withValues(alpha: .22),
          radius: 16,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: presentation.accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                presentation.icon,
                color: presentation.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          filter.id == 'all'
                              ? 'All ${presentation.familyLabel} conversations'
                              : '${filter.label} conversations',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyBody.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: presentation.accent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: presentation.accent,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'MoolSocial',
                              style: context.buyMeta.copyWith(
                                color: presentation.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$conversationCount ${conversationCount == 1 ? 'conversation' : 'conversations'} available · ${presentation.securityMessage}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyMeta.copyWith(fontSize: 9),
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

class _ShopChatEntryTile extends StatelessWidget {
  const _ShopChatEntryTile({
    required this.entry,
    required this.categoryLabel,
    required this.onTap,
  });

  final BuyV2ShopChatThread entry;
  final String categoryLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    void openChat() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Semantics(
      key: ValueKey('buy-shop-chat-entry-${entry.id}'),
      button: true,
      label:
          '${entry.title}. ${entry.subtitle}. ${entry.detail}. Continue in Chat.',
      onTap: openChat,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: BuyV2IntentDepth(
          child: Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: BuyV2Colors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: openChat,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 76),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: entry.accent.withValues(alpha: .11),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(entry.icon, color: entry.accent, size: 23),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.buyBody.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.previewTimeLabel ?? categoryLabel,
                                  style: context.buyMeta.copyWith(
                                    color: entry.unreadCount > 0
                                        ? BuyV2Colors.green
                                        : entry.accent,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entry.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(
                                color: BuyV2Colors.ink,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.detail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.buyMeta.copyWith(
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                if (entry.unreadCount > 0)
                                  Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 19,
                                      minHeight: 19,
                                    ),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: BuyV2Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${entry.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopChatEmptyState extends StatelessWidget {
  const _ShopChatEmptyState({
    required this.familyLabel,
    required this.query,
    required this.filterLabel,
    required this.hasProvisionedEntries,
    required this.onClearSearch,
    required this.onShowAll,
    required this.onChooseConversation,
    required this.onOpenAll,
  });

  final String familyLabel;
  final String query;
  final String? filterLabel;
  final bool hasProvisionedEntries;
  final VoidCallback onClearSearch;
  final VoidCallback onShowAll;
  final VoidCallback onChooseConversation;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final (title, detail, actionLabel, actionKey, action) = query.isNotEmpty
        ? (
            'No conversations match “$query”',
            'Clear the search to see your $familyLabel conversations.',
            'Clear search',
            'buy-shop-chat-empty-clear-search',
            onClearSearch,
          )
        : filterLabel != null
        ? (
            'No $filterLabel conversations yet',
            'Show all $familyLabel conversations or choose another category.',
            'Show all',
            'buy-shop-chat-empty-show-all',
            onShowAll,
          )
        : !hasProvisionedEntries
        ? (
            'No $familyLabel conversations are available yet',
            'Open all MoolSocial chats to continue.',
            'Open all chats',
            'buy-shop-chat-empty-open-all',
            onOpenAll,
          )
        : (
            'No $familyLabel conversations yet',
            'Choose a conversation to start in MoolSocial Chat.',
            'Choose conversation',
            'buy-shop-chat-empty-choose',
            onChooseConversation,
          );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: BuyV2Colors.muted,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.buyBody,
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.buyMeta,
            ),
            const SizedBox(height: 14),
            FilledButton(
              key: ValueKey(actionKey),
              onPressed: action,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: BuyV2Colors.navy,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _ShopChatDispatch =
    Future<BuyV2ShopChatActionResult> Function(BuyV2ShopChatAction action);

class _ShopChatNewConversationView extends StatelessWidget {
  const _ShopChatNewConversationView({
    required this.entries,
    required this.presentation,
    required this.navigationForward,
    required this.onBack,
    required this.onSelected,
    required this.onOpenAll,
  });

  final List<BuyV2ShopChatThread> entries;
  final BuyV2ShopChatPresentation presentation;
  final Widget? navigationForward;
  final VoidCallback onBack;
  final ValueChanged<BuyV2ShopChatThread> onSelected;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('buy-shop-chat-new-surface'),
      color: const Color(0xFFF8F8FC),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 72),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: BuyV2Colors.line)),
              gradient: LinearGradient(
                colors: [
                  presentation.accent.withValues(alpha: .08),
                  Colors.white,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('buy-shop-chat-new-back'),
                  tooltip: 'Back to ${presentation.familyLabel} chats',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: presentation.accent.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a ${presentation.familyLabel} conversation',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'MoolSocial Chat · choose a conversation context',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          ?navigationForward,
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
              decoration: buyV2CardDecoration(
                color: presentation.accent.withValues(alpha: .06),
                border: presentation.accent.withValues(alpha: .18),
                radius: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: presentation.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      presentation.newConversationPrompt,
                      style: context.buyMeta.copyWith(
                        color: BuyV2Colors.ink,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? _ShopChatNewConversationEmptyState(
                    familyLabel: presentation.familyLabel,
                    onOpenAll: onOpenAll,
                  )
                : ListView.separated(
                    key: PageStorageKey<String>(
                      'buy-shop-chat-new-list-${presentation.familyId}',
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: BuyV2Colors.line),
                        ),
                        child: ListTile(
                          key: ValueKey('buy-shop-chat-new-${entry.id}'),
                          minTileHeight: 64,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: entry.accent.withValues(
                              alpha: .11,
                            ),
                            foregroundColor: entry.accent,
                            child: Icon(entry.icon),
                          ),
                          title: Text(entry.title, style: context.buyBody),
                          subtitle: Text(
                            entry.subtitle,
                            style: context.buyMeta,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: entry.accent.withValues(alpha: .09),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  presentation
                                      .filter(entry.resolvedFilterId)
                                      .label,
                                  style: context.buyMeta.copyWith(
                                    color: entry.accent,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          onTap: () => onSelected(entry),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShopChatNewConversationEmptyState extends StatelessWidget {
  const _ShopChatNewConversationEmptyState({
    required this.familyLabel,
    required this.onOpenAll,
  });

  final String familyLabel;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 34,
              color: BuyV2Colors.muted,
            ),
            const SizedBox(height: 10),
            Text(
              'No $familyLabel conversation choices yet',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.buyBody,
            ),
            const SizedBox(height: 4),
            Text(
              'Open all MoolSocial chats to continue.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.buyMeta,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const ValueKey('buy-shop-chat-new-open-all'),
              onPressed: onOpenAll,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                backgroundColor: BuyV2Colors.navy,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Open all chats'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatConversationView extends StatefulWidget {
  const _ShopChatConversationView({
    super.key,
    required this.thread,
    required this.retainedState,
    required this.navigationForward,
    required this.onBack,
    required this.onOpenInfo,
    required this.onDispatch,
    required this.onOpenContext,
    required this.presentation,
  });

  final BuyV2ShopChatThread thread;
  final _BuyV2ShopChatThreadRetainedState retainedState;
  final Widget? navigationForward;
  final VoidCallback onBack;
  final VoidCallback onOpenInfo;
  final _ShopChatDispatch onDispatch;
  final VoidCallback? onOpenContext;
  final BuyV2ShopChatPresentation presentation;

  @override
  State<_ShopChatConversationView> createState() =>
      _ShopChatConversationViewState();
}

class _ShopChatConversationViewState extends State<_ShopChatConversationView> {
  late final TextEditingController _composerController;
  late final TextEditingController _messageSearchController;
  late final FocusNode _composerFocusNode;
  late BuyV2ShopChatMessage? _replyTarget;
  BuyV2ShopChatMessage? _selectedMessage;
  bool _emojiOpen = false;
  late bool _searchOpen;
  bool _attachmentOpen = false;
  bool _threadMenuOpen = false;
  bool _dispatching = false;
  BuyV2ShopChatActionKind? _activeAction;
  final List<_BuyV2ShopChatThreadHistoryEntry> _forwardHistory = [];

  @override
  void initState() {
    super.initState();
    final retained = widget.retainedState;
    _composerController = TextEditingController(text: retained.draft);
    _messageSearchController = TextEditingController(
      text: retained.messageQuery,
    );
    _composerFocusNode = FocusNode(debugLabel: 'Shop Chat composer');
    _replyTarget = _messageForId(retained.replyMessageId);
    if (_replyTarget == null) retained.replyMessageId = null;
    _searchOpen = retained.messageSearchOpen;
    _composerController.addListener(_retainComposer);
    _messageSearchController.addListener(_retainMessageSearch);
  }

  bool handleBack({required bool dismissComposerKeyboard}) {
    if (_selectedMessage != null) {
      setState(() {
        _forwardHistory.add(
          _BuyV2ShopChatThreadHistoryEntry(
            utility: _BuyV2ShopChatThreadUtility.messageActions,
            message: _selectedMessage,
          ),
        );
        _selectedMessage = null;
      });
      return true;
    }
    if (_threadMenuOpen) {
      setState(() {
        _forwardHistory.add(
          const _BuyV2ShopChatThreadHistoryEntry(
            utility: _BuyV2ShopChatThreadUtility.conversationOptions,
          ),
        );
        _threadMenuOpen = false;
      });
      return true;
    }
    if (_searchOpen) {
      final query = _messageSearchController.text;
      _messageSearchController.clear();
      setState(() {
        _forwardHistory.add(
          _BuyV2ShopChatThreadHistoryEntry(
            utility: _BuyV2ShopChatThreadUtility.messageSearch,
            messageQuery: query,
          ),
        );
        _setSearchOpen(false);
      });
      return true;
    }
    if (_attachmentOpen) {
      setState(() {
        _forwardHistory.add(
          const _BuyV2ShopChatThreadHistoryEntry(
            utility: _BuyV2ShopChatThreadUtility.attachmentChoices,
          ),
        );
        _attachmentOpen = false;
      });
      return true;
    }
    if (_emojiOpen) {
      setState(() {
        _forwardHistory.add(
          const _BuyV2ShopChatThreadHistoryEntry(
            utility: _BuyV2ShopChatThreadUtility.emojiChoices,
          ),
        );
        _emojiOpen = false;
      });
      return true;
    }
    if (dismissComposerKeyboard && _composerFocusNode.hasFocus) {
      _composerFocusNode.unfocus();
      return true;
    }
    if (_replyTarget != null) {
      setState(() {
        _forwardHistory.add(
          _BuyV2ShopChatThreadHistoryEntry(
            utility: _BuyV2ShopChatThreadUtility.reply,
            message: _replyTarget,
          ),
        );
        _setReplyTarget(null);
      });
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _composerController.removeListener(_retainComposer);
    _messageSearchController.removeListener(_retainMessageSearch);
    _composerFocusNode.dispose();
    _composerController.dispose();
    _messageSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _visibleMessages();
    final messageListState = _messageSearchController.text.trim().isEmpty
        ? 'all'
        : 'search-${_messageSearchController.text.trim().toLowerCase()}';
    final navigationForward = _forwardHistory.isEmpty
        ? widget.navigationForward
        : _ShopChatNavigationForwardBar(
            destination: _forwardHistory.last.destination,
            onPressed: _showForwardHistory,
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactInputSurface =
            constraints.maxWidth <= 340 || constraints.maxHeight < 420;
        return Semantics(
          key: const ValueKey('buy-shop-chat-thread'),
          container: true,
          label: '${widget.thread.title} conversation',
          child: ColoredBox(
            color: const Color(0xFFF2F3F9),
            child: Column(
              children: [
                if (_selectedMessage case final selected?)
                  _ShopChatSelectionHeader(
                    familyLabel: widget.presentation.familyLabel,
                    onClose: () => setState(() => _selectedMessage = null),
                    onReply: () {
                      setState(() {
                        _forwardHistory.clear();
                        _setReplyTarget(selected);
                        _selectedMessage = null;
                      });
                    },
                    onReact: _dispatching
                        ? null
                        : () => _dispatchDirect(
                            BuyV2ShopChatActionKind.reactToMessage,
                            message: selected,
                            text: 'like',
                          ),
                    onCopy: () => _copyMessage(selected),
                    onForward: _dispatching
                        ? null
                        : () => _dispatchDirect(
                            BuyV2ShopChatActionKind.forwardMessage,
                            message: selected,
                          ),
                  )
                else
                  _ShopChatThreadHeader(
                    thread: widget.thread,
                    presentation: widget.presentation,
                    busy: _dispatching,
                    onBack: widget.onBack,
                    onOpenInfo: widget.onOpenInfo,
                    onVoiceCall: widget.thread.capabilities.voiceCall
                        ? () => _dispatchDirect(
                            BuyV2ShopChatActionKind.startVoiceCall,
                          )
                        : null,
                    onVideoCall: widget.thread.capabilities.videoCall
                        ? () => _dispatchDirect(
                            BuyV2ShopChatActionKind.startVideoCall,
                          )
                        : null,
                    onMore: () => setState(() {
                      _forwardHistory.clear();
                      _threadMenuOpen = !_threadMenuOpen;
                      _attachmentOpen = false;
                    }),
                  ),
                ?navigationForward,
                if (_threadMenuOpen)
                  _ShopChatInlineThreadMenu(
                    presentation: widget.presentation,
                    onInfo: () {
                      setState(() => _threadMenuOpen = false);
                      widget.onOpenInfo();
                    },
                    onSearch: () => setState(() {
                      _forwardHistory.clear();
                      _threadMenuOpen = false;
                      _setSearchOpen(true);
                    }),
                    onNotifications: _dispatching
                        ? null
                        : () => _dispatchDirect(
                            BuyV2ShopChatActionKind.manageNotifications,
                          ),
                    onSafety: _dispatching
                        ? null
                        : () => _dispatchDirect(
                            BuyV2ShopChatActionKind.openSafety,
                          ),
                  ),
                if (_searchOpen)
                  _ShopChatMessageSearch(
                    threadTitle: widget.thread.title,
                    controller: _messageSearchController,
                    onChanged: (_) => setState(() {}),
                    onClose: () {
                      _messageSearchController.clear();
                      setState(() => _setSearchOpen(false));
                    },
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _ShopChatConversationCanvas(
                          accent: widget.presentation.accent,
                        ),
                      ),
                      Positioned.fill(
                        child: BuyV2ShopChatFilterMotion(
                          stateKey:
                              '${widget.thread.id}|${_messageSearchController.text}',
                          child: ListView(
                            key: PageStorageKey<String>(
                              'buy-shop-chat-message-list-${widget.thread.id}-$messageListState',
                            ),
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                            children: [
                              _ShopChatCommerceContext(
                                thread: widget.thread,
                                onTap: widget.onOpenContext,
                                familyLabel: widget.presentation.familyLabel,
                              ),
                              if (widget.presentation.familyId == 'book') ...[
                                const SizedBox(height: 10),
                                _ShopChatCareSafetyNotice(
                                  message: widget.presentation.securityMessage,
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (messages.isEmpty)
                                _ShopChatWelcomePanel(
                                  thread: widget.thread,
                                  presentation: widget.presentation,
                                )
                              else ...[
                                const Center(child: _ShopChatDayChip()),
                                const SizedBox(height: 10),
                                ...messages.map(
                                  (message) => _ShopChatMessageBubble(
                                    message: message,
                                    onForward: _dispatching
                                        ? null
                                        : () => _dispatchDirect(
                                            BuyV2ShopChatActionKind
                                                .forwardMessage,
                                            message: message,
                                          ),
                                    onTap:
                                        _dispatching ||
                                            message.kind ==
                                                BuyV2ShopChatMessageKind.text
                                        ? null
                                        : () => _dispatchDirect(
                                            BuyV2ShopChatActionKind
                                                .openAttachment,
                                            message: message,
                                          ),
                                    onLongPress: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() {
                                        _forwardHistory.clear();
                                        _selectedMessage = message;
                                      });
                                    },
                                  ),
                                ),
                              ],
                              if (_messageSearchController.text
                                  .trim()
                                  .isEmpty) ...[
                                const SizedBox(height: 12),
                                _ShopChatQuickReplies(
                                  values: widget.thread.quickReplies,
                                  onSelected: (value) {
                                    _composerController.text = value;
                                    _composerController.selection =
                                        TextSelection.collapsed(
                                          offset: value.length,
                                        );
                                    setState(() => _emojiOpen = false);
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_attachmentOpen)
                  _ShopChatInlineAttachmentTray(
                    capabilities: widget.thread.capabilities,
                    presentation: widget.presentation,
                    compact: compactInputSurface,
                    onSelected: (kind) {
                      setState(() => _attachmentOpen = false);
                      _dispatchDirect(kind);
                    },
                  ),
                _ShopChatComposer(
                  controller: _composerController,
                  focusNode: _composerFocusNode,
                  replyTarget: _replyTarget,
                  emojiOpen: _emojiOpen,
                  busy: _dispatching,
                  busyLabel:
                      _activeAction?.inProgressMessage ??
                      'Completing Chat action',
                  onChanged: (_) => setState(() {}),
                  onTapField: () {
                    if (!_emojiOpen && !_attachmentOpen) return;
                    setState(() {
                      _forwardHistory.clear();
                      _emojiOpen = false;
                      _attachmentOpen = false;
                    });
                  },
                  onCancelReply: () => setState(() => _setReplyTarget(null)),
                  onToggleEmoji: () {
                    final willOpen = !_emojiOpen;
                    if (willOpen) FocusScope.of(context).unfocus();
                    setState(() {
                      _forwardHistory.clear();
                      _emojiOpen = willOpen;
                      _attachmentOpen = false;
                      _threadMenuOpen = false;
                    });
                  },
                  onEmoji: (emoji) {
                    final value = '${_composerController.text}$emoji';
                    _composerController.text = value;
                    _composerController.selection = TextSelection.collapsed(
                      offset: value.length,
                    );
                    setState(() {});
                  },
                  onAttachment: widget.thread.capabilities.canAttach
                      ? () {
                          final willOpen = !_attachmentOpen;
                          if (willOpen) FocusScope.of(context).unfocus();
                          setState(() {
                            _forwardHistory.clear();
                            _attachmentOpen = willOpen;
                            _threadMenuOpen = false;
                            _emojiOpen = false;
                          });
                        }
                      : null,
                  onCamera: widget.thread.capabilities.camera
                      ? () => _dispatchDirect(
                          BuyV2ShopChatActionKind.captureImage,
                        )
                      : null,
                  onSend: _sendText,
                  onVoice: widget.thread.capabilities.voiceMessages
                      ? () =>
                            _dispatchDirect(BuyV2ShopChatActionKind.recordVoice)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<BuyV2ShopChatMessage> _visibleMessages() {
    final query = _messageSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.thread.messages;
    return widget.thread.messages
        .where(
          (message) => [
            message.body,
            message.attachmentName,
            message.attachmentDetail,
          ].whereType<String>().join(' ').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> _sendText() async {
    final text = _composerController.text.trim();
    if (text.isEmpty || _dispatching) return;
    setState(() {
      _dispatching = true;
      _activeAction = BuyV2ShopChatActionKind.sendText;
    });
    final result = await widget.onDispatch(
      BuyV2ShopChatAction(
        kind: BuyV2ShopChatActionKind.sendText,
        threadId: widget.thread.id,
        text: text,
        replyToMessageId: _replyTarget?.id,
      ),
    );
    if (!mounted) return;
    if (result.disposition == BuyV2ShopChatActionDisposition.accepted) {
      _composerController.clear();
      _setReplyTarget(null);
      _emojiOpen = false;
    }
    setState(() {
      _dispatching = false;
      _activeAction = null;
    });
    _report(result);
  }

  Future<void> _dispatchDirect(
    BuyV2ShopChatActionKind kind, {
    BuyV2ShopChatMessage? message,
    String? text,
  }) async {
    HapticFeedback.selectionClick();
    if (_dispatching) return;
    setState(() {
      _dispatching = true;
      _activeAction = kind;
      _threadMenuOpen = false;
    });
    final result = await widget.onDispatch(
      BuyV2ShopChatAction(
        kind: kind,
        threadId: widget.thread.id,
        text: text,
        messageId: message?.id,
        replyToMessageId: _replyTarget?.id,
      ),
    );
    if (!mounted) return;
    setState(() {
      _dispatching = false;
      _activeAction = null;
      _selectedMessage = null;
    });
    _report(result);
  }

  Future<void> _copyMessage(BuyV2ShopChatMessage message) async {
    final value = message.body ?? message.attachmentName;
    if (value == null) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => _selectedMessage = null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message copied')));
  }

  void _report(BuyV2ShopChatActionResult result) {
    final message = result.customerMessage;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    if (message == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 82),
      ),
    );
  }

  BuyV2ShopChatMessage? _messageForId(String? messageId) {
    if (messageId == null) return null;
    for (final message in widget.thread.messages) {
      if (message.id == messageId) return message;
    }
    return null;
  }

  void _setReplyTarget(BuyV2ShopChatMessage? message) {
    _replyTarget = message;
    widget.retainedState.replyMessageId = message?.id;
  }

  void _setSearchOpen(bool value) {
    _searchOpen = value;
    widget.retainedState.messageSearchOpen = value;
  }

  void _retainComposer() {
    widget.retainedState.draft = _composerController.text;
  }

  void _retainMessageSearch() {
    widget.retainedState.messageQuery = _messageSearchController.text;
  }

  void _showForwardHistory() {
    if (_forwardHistory.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      final target = _forwardHistory.removeLast();
      switch (target.utility) {
        case _BuyV2ShopChatThreadUtility.messageActions:
          _selectedMessage = target.message;
        case _BuyV2ShopChatThreadUtility.conversationOptions:
          _threadMenuOpen = true;
        case _BuyV2ShopChatThreadUtility.messageSearch:
          _messageSearchController.text = target.messageQuery ?? '';
          _messageSearchController.selection = TextSelection.collapsed(
            offset: _messageSearchController.text.length,
          );
          _setSearchOpen(true);
        case _BuyV2ShopChatThreadUtility.attachmentChoices:
          _attachmentOpen = true;
        case _BuyV2ShopChatThreadUtility.emojiChoices:
          _emojiOpen = true;
        case _BuyV2ShopChatThreadUtility.reply:
          _setReplyTarget(target.message);
      }
    });
  }
}

class _ShopChatThreadHeader extends StatelessWidget {
  const _ShopChatThreadHeader({
    required this.thread,
    required this.presentation,
    required this.busy,
    required this.onBack,
    required this.onOpenInfo,
    required this.onVoiceCall,
    required this.onVideoCall,
    required this.onMore,
  });

  final BuyV2ShopChatThread thread;
  final BuyV2ShopChatPresentation presentation;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback onOpenInfo;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onVideoCall;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(2, 5, 2, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: BuyV2Colors.line)),
        gradient: LinearGradient(
          colors: [
            presentation.accent.withValues(alpha: .06),
            Colors.white,
            BuyV2Colors.softBlue.withValues(alpha: .24),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('buy-shop-chat-thread-back'),
            tooltip: 'Back to ${presentation.familyLabel} chats',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          InkWell(
            key: const ValueKey('buy-shop-chat-thread-info'),
            borderRadius: BorderRadius.circular(14),
            onTap: onOpenInfo,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  _ShopChatAvatar(thread: thread, size: 40),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: MediaQuery.sizeOf(context).width < 360 ? 76 : 132,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          thread.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyBody.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${presentation.familyLabel} · ${thread.participantKind.customerLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyMeta.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (onVoiceCall != null)
            IconButton(
              key: const ValueKey('buy-shop-chat-voice-call'),
              tooltip: 'Voice call',
              onPressed: busy ? null : onVoiceCall,
              icon: const Icon(Icons.call_outlined),
              color: BuyV2Colors.navy,
              disabledColor: BuyV2Colors.muted,
            ),
          if (onVideoCall != null)
            IconButton(
              key: const ValueKey('buy-shop-chat-video-call'),
              tooltip: 'Video call',
              onPressed: busy ? null : onVideoCall,
              icon: const Icon(Icons.videocam_outlined),
              color: BuyV2Colors.navy,
              disabledColor: BuyV2Colors.muted,
            ),
          IconButton(
            key: const ValueKey('buy-shop-chat-thread-more'),
            tooltip: 'Conversation options',
            onPressed: onMore,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }
}

class _ShopChatSelectionHeader extends StatelessWidget {
  const _ShopChatSelectionHeader({
    required this.familyLabel,
    required this.onClose,
    required this.onReply,
    required this.onReact,
    required this.onCopy,
    required this.onForward,
  });

  final String familyLabel;
  final VoidCallback onClose;
  final VoidCallback onReply;
  final VoidCallback? onReact;
  final VoidCallback onCopy;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('buy-shop-chat-message-actions'),
      color: Colors.white,
      elevation: 2,
      child: SizedBox(
        height: 66,
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('buy-shop-chat-selection-close'),
              tooltip: 'Close message actions',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
            Expanded(
              child: Text(
                '1 selected · $familyLabel',
                maxLines: 1,
                style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              key: const ValueKey('buy-shop-chat-menu-reply'),
              tooltip: 'Reply',
              onPressed: onReply,
              icon: const Icon(Icons.reply_rounded),
              color: BuyV2Colors.navy,
            ),
            IconButton(
              key: const ValueKey('buy-shop-chat-menu-react'),
              tooltip: 'Like',
              onPressed: onReact,
              icon: const Icon(Icons.thumb_up_alt_outlined),
              color: BuyV2Colors.navy,
            ),
            IconButton(
              key: const ValueKey('buy-shop-chat-menu-copy'),
              tooltip: 'Copy',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
              color: BuyV2Colors.navy,
            ),
            IconButton(
              key: const ValueKey('buy-shop-chat-menu-forward'),
              tooltip: 'Forward',
              onPressed: onForward,
              icon: const Icon(Icons.forward_rounded),
              color: BuyV2Colors.navy,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatInlineThreadMenu extends StatelessWidget {
  const _ShopChatInlineThreadMenu({
    required this.presentation,
    required this.onInfo,
    required this.onSearch,
    required this.onNotifications,
    required this.onSafety,
  });

  final BuyV2ShopChatPresentation presentation;
  final VoidCallback onInfo;
  final VoidCallback onSearch;
  final VoidCallback? onNotifications;
  final VoidCallback? onSafety;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('buy-shop-chat-thread-menu'),
      color: Colors.white,
      elevation: 3,
      child: SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          children: [
            _ShopChatInlineMenuAction(
              keyName: 'info',
              icon: presentation.icon,
              label: '${presentation.familyLabel} info',
              onTap: onInfo,
            ),
            _ShopChatInlineMenuAction(
              keyName: 'search',
              icon: Icons.search_rounded,
              label: 'Search',
              onTap: onSearch,
            ),
            _ShopChatInlineMenuAction(
              keyName: 'notifications',
              icon: Icons.notifications_outlined,
              label: 'Alerts',
              onTap: onNotifications,
            ),
            _ShopChatInlineMenuAction(
              keyName: 'safety',
              icon: Icons.shield_outlined,
              label: 'Safety',
              onTap: onSafety,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatInlineMenuAction extends StatelessWidget {
  const _ShopChatInlineMenuAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: 91,
      child: InkWell(
        key: ValueKey('buy-shop-chat-menu-$keyName'),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: enabled ? BuyV2Colors.navy : BuyV2Colors.muted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: enabled ? BuyV2Colors.navy : BuyV2Colors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatMessageSearch extends StatelessWidget {
  const _ShopChatMessageSearch({
    required this.threadTitle,
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  final String threadTitle;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('buy-shop-chat-message-search'),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
      child: SizedBox(
        height: 44,
        child: TextField(
          key: const ValueKey('buy-shop-chat-message-search-field'),
          controller: controller,
          autofocus: true,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search $threadTitle',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              key: const ValueKey('buy-shop-chat-message-search-close'),
              tooltip: 'Close search',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
            filled: true,
            fillColor: const Color(0xFFF4F5FA),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopChatConversationCanvas extends StatelessWidget {
  const _ShopChatConversationCanvas({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: .045),
            BuyV2Colors.softBlue.withValues(alpha: .48),
            const Color(0xFFF7F7FB),
          ],
        ),
      ),
    );
  }
}

class _ShopChatCommerceContext extends StatelessWidget {
  const _ShopChatCommerceContext({
    required this.thread,
    required this.onTap,
    required this.familyLabel,
  });

  final BuyV2ShopChatThread thread;
  final VoidCallback? onTap;
  final String familyLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${thread.contextTitle}. ${thread.contextDetail}',
      child: Material(
        color: Colors.white.withValues(alpha: .96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: thread.accent.withValues(alpha: .22)),
        ),
        child: InkWell(
          key: const ValueKey('buy-shop-chat-commerce-context'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                _ShopChatAvatar(thread: thread, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              thread.contextTitle,
                              style: context.buyBody,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: thread.accent.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$familyLabel context',
                              style: context.buyMeta.copyWith(
                                color: thread.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        thread.contextDetail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: BuyV2Colors.navy,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopChatCareSafetyNotice extends StatelessWidget {
  const _ShopChatCareSafetyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('buy-shop-chat-care-safety'),
      container: true,
      excludeSemantics: true,
      label: 'Care Chat safety notice. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: buyV2CardDecoration(
          color: const Color(0xFFFFF8E7),
          border: const Color(0xFFE7B84B).withValues(alpha: .55),
          radius: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFF8A5A00),
              size: 19,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: context.buyMeta.copyWith(
                  color: const Color(0xFF5F4307),
                  fontSize: 10.5,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatWelcomePanel extends StatelessWidget {
  const _ShopChatWelcomePanel({
    required this.thread,
    required this.presentation,
  });

  final BuyV2ShopChatThread thread;
  final BuyV2ShopChatPresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(18),
        decoration: buyV2CardDecoration(
          color: Colors.white.withValues(alpha: .94),
          border: presentation.accent.withValues(alpha: .16),
          radius: 20,
          shadow: true,
        ),
        child: Column(
          children: [
            _ShopChatAvatar(thread: thread, size: 58),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: presentation.accent.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${presentation.familyLabel} · ${thread.contextTitle}',
                style: context.buyMeta.copyWith(
                  color: presentation.accent,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Continue with ${thread.title}',
              textAlign: TextAlign.center,
              style: context.buyBody.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              'Messages and shared items appear here after Chat confirms them.',
              textAlign: TextAlign.center,
              style: context.buyMeta.copyWith(fontSize: 10.5),
            ),
            const SizedBox(height: 10),
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: presentation.accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatDayChip extends StatelessWidget {
  const _ShopChatDayChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BuyV2Colors.line),
      ),
      child: Text('Today', style: context.buyMeta.copyWith(fontSize: 9)),
    );
  }
}

class _ShopChatQuickReplies extends StatelessWidget {
  const _ShopChatQuickReplies({required this.values, required this.onSelected});

  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Wrap(
      key: const ValueKey('buy-shop-chat-quick-replies'),
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: values
          .map(
            (value) => ActionChip(
              key: ValueKey('buy-shop-chat-quick-${value.hashCode}'),
              avatar: const Icon(Icons.auto_awesome_outlined, size: 15),
              label: Text(value),
              onPressed: () => onSelected(value),
              backgroundColor: Colors.white.withValues(alpha: .96),
              side: const BorderSide(color: BuyV2Colors.line),
              labelStyle: context.buyMeta.copyWith(
                color: BuyV2Colors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ShopChatComposer extends StatelessWidget {
  const _ShopChatComposer({
    required this.controller,
    required this.focusNode,
    required this.replyTarget,
    required this.emojiOpen,
    required this.busy,
    required this.busyLabel,
    required this.onChanged,
    required this.onTapField,
    required this.onCancelReply,
    required this.onToggleEmoji,
    required this.onEmoji,
    required this.onAttachment,
    required this.onCamera,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final BuyV2ShopChatMessage? replyTarget;
  final bool emojiOpen;
  final bool busy;
  final String busyLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onTapField;
  final VoidCallback onCancelReply;
  final VoidCallback onToggleEmoji;
  final ValueChanged<String> onEmoji;
  final VoidCallback? onAttachment;
  final VoidCallback? onCamera;
  final VoidCallback onSend;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    final canSend = controller.text.trim().isNotEmpty;
    final canRecordVoice = onVoice != null;
    final primaryEnabled = !busy && (canSend || canRecordVoice);
    final primaryLabel = busy
        ? busyLabel
        : canSend
        ? 'Send message'
        : canRecordVoice
        ? 'Record voice message'
        : 'Type a message to send';
    return Material(
      key: const ValueKey('buy-shop-chat-composer'),
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x22000040),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTarget != null)
              _ShopChatReplyPreview(
                message: replyTarget!,
                onClose: onCancelReply,
              ),
            if (emojiOpen)
              SizedBox(
                key: const ValueKey('buy-shop-chat-emoji-tray'),
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children:
                      const [
                            (
                              '😀',
                              'Happy',
                              Icons.sentiment_very_satisfied_rounded,
                            ),
                            ('👍', 'Like', Icons.thumb_up_alt_rounded),
                            ('🙏', 'Thanks', Icons.volunteer_activism_rounded),
                            ('❤️', 'Love', Icons.favorite_rounded),
                            ('🎉', 'Celebrate', Icons.celebration_rounded),
                            (
                              '😊',
                              'Smile',
                              Icons.sentiment_satisfied_alt_rounded,
                            ),
                          ]
                          .map(
                            (reaction) => IconButton(
                              tooltip: 'Add ${reaction.$2}',
                              onPressed: () => onEmoji(reaction.$1),
                              icon: Icon(reaction.$3, size: 21),
                              color: BuyV2Colors.navy,
                            ),
                          )
                          .toList(growable: false),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 8, 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _ShopChatComposerIcon(
                            key: const ValueKey('buy-shop-chat-emoji'),
                            tooltip: 'Emoji',
                            onPressed: busy ? null : onToggleEmoji,
                            icon: emojiOpen
                                ? Icons.keyboard_alt_outlined
                                : Icons.sentiment_satisfied_alt_outlined,
                          ),
                          Expanded(
                            child: TextField(
                              key: const ValueKey(
                                'buy-shop-chat-composer-field',
                              ),
                              controller: controller,
                              focusNode: focusNode,
                              onChanged: onChanged,
                              onTap: onTapField,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                isDense: true,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 13,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (onAttachment != null)
                            _ShopChatComposerIcon(
                              key: const ValueKey('buy-shop-chat-attach'),
                              tooltip: 'Share in this conversation',
                              onPressed: busy ? null : onAttachment,
                              icon: Icons.attach_file_rounded,
                            ),
                          if (onCamera != null)
                            _ShopChatComposerIcon(
                              key: const ValueKey('buy-shop-chat-camera'),
                              tooltip: 'Camera',
                              onPressed: busy ? null : onCamera,
                              icon: Icons.camera_alt_outlined,
                            ),
                          const SizedBox(width: 2),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Semantics(
                    button: true,
                    enabled: primaryEnabled,
                    liveRegion: busy,
                    label: primaryLabel,
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: FloatingActionButton.small(
                        key: ValueKey(
                          canSend
                              ? 'buy-shop-chat-send'
                              : canRecordVoice
                              ? 'buy-shop-chat-voice'
                              : 'buy-shop-chat-send-disabled',
                        ),
                        heroTag: null,
                        elevation: 0,
                        backgroundColor: BuyV2Colors.navy,
                        foregroundColor: Colors.white,
                        onPressed: primaryEnabled
                            ? canSend
                                  ? onSend
                                  : onVoice
                            : null,
                        child: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                canSend
                                    ? Icons.send_rounded
                                    : canRecordVoice
                                    ? Icons.mic_none_rounded
                                    : Icons.send_rounded,
                                size: 21,
                              ),
                      ),
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

class _ShopChatComposerIcon extends StatelessWidget {
  const _ShopChatComposerIcon({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
      color: BuyV2Colors.muted,
      constraints: const BoxConstraints.tightFor(width: 44, height: 46),
      padding: EdgeInsets.zero,
    );
  }
}

class _ShopChatReplyPreview extends StatelessWidget {
  const _ShopChatReplyPreview({required this.message, required this.onClose});

  final BuyV2ShopChatMessage message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('buy-shop-chat-reply-preview'),
      constraints: const BoxConstraints(minHeight: 46),
      margin: const EdgeInsets.fromLTRB(12, 7, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 5, 2, 5),
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: BuyV2Colors.navy, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message.body ?? message.attachmentName ?? 'Shared message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.buyMeta.copyWith(color: BuyV2Colors.ink),
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ShopChatAvatar extends StatelessWidget {
  const _ShopChatAvatar({required this.thread, required this.size});

  final BuyV2ShopChatThread thread;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [thread.accent, thread.accent.withValues(alpha: .72)],
        ),
        borderRadius: BorderRadius.circular(size * .34),
      ),
      child: Icon(thread.icon, color: Colors.white, size: size * .5),
    );
  }
}

class _ShopChatMessageBubble extends StatelessWidget {
  const _ShopChatMessageBubble({
    required this.message,
    required this.onForward,
    required this.onTap,
    required this.onLongPress,
  });

  final BuyV2ShopChatMessage message;
  final VoidCallback? onForward;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromCurrentUser;
    final bubbleColor = mine ? const Color(0xFFE5E4FF) : Colors.white;
    final details =
        [message.attachmentName, message.body, message.attachmentDetail]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .map(
              (value) => RegExp(r'[.!?]$').hasMatch(value) ? value : '$value.',
            )
            .join(' ');
    final accessibilityLabel = [
      '${mine ? 'Sent' : 'Received'} ${message.kind.customerLabel} at ${message.sentAtLabel}.',
      if (details.isNotEmpty) details,
      if (mine) '${message.deliveryState.customerLabel}.',
    ].join(' ');
    final forward = _ShopChatMessageForwardButton(
      message: message,
      onPressed: onForward,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (mine) ...[forward, const SizedBox(width: 6)],
          Flexible(
            child: Semantics(
              container: true,
              button: onTap != null,
              label: accessibilityLabel,
              hint: onTap == null
                  ? 'Long press for Reply, Like, Copy, and Forward.'
                  : 'Double tap to open. Long press for Reply, Like, Copy, and Forward.',
              excludeSemantics: true,
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 92,
                  maxWidth: MediaQuery.sizeOf(context).width * .68,
                ),
                child: BuyV2IntentDepth(
                  child: Material(
                    color: bubbleColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(mine ? 16 : 4),
                        bottomRight: Radius.circular(mine ? 4 : 16),
                      ),
                      side: const BorderSide(color: BuyV2Colors.line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('buy-shop-chat-message-${message.id}'),
                      onTap: onTap,
                      onLongPress: onLongPress,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.replyToLabel != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .62),
                                  borderRadius: BorderRadius.circular(9),
                                  border: const Border(
                                    left: BorderSide(
                                      color: BuyV2Colors.navy,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  message.replyToLabel!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.buyMeta.copyWith(fontSize: 9),
                                ),
                              ),
                            _ShopChatMessageContent(message: message),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.reaction != null) ...[
                                  Text(
                                    message.reaction!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  message.sentAtLabel,
                                  style: context.buyMeta.copyWith(
                                    fontSize: 8.5,
                                  ),
                                ),
                                if (mine) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.deliveryState.deliveryIcon,
                                    size: 14,
                                    color:
                                        message.deliveryState ==
                                            BuyV2ShopChatDeliveryState.read
                                        ? BuyV2Colors.royal
                                        : message.deliveryState ==
                                              BuyV2ShopChatDeliveryState.failed
                                        ? Colors.redAccent
                                        : BuyV2Colors.muted,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!mine) ...[const SizedBox(width: 6), forward],
        ],
      ),
    );
  }
}

class _ShopChatMessageForwardButton extends StatelessWidget {
  const _ShopChatMessageForwardButton({
    required this.message,
    required this.onPressed,
  });

  final BuyV2ShopChatMessage message;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final direction = message.fromCurrentUser ? 'sent' : 'received';
    return Semantics(
      key: ValueKey('buy-shop-chat-forward-${message.id}'),
      container: true,
      button: true,
      enabled: onPressed != null,
      label: 'Forward $direction message from ${message.sentAtLabel}',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Forward message',
        child: SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            iconSize: 18,
            color: onPressed == null ? BuyV2Colors.muted : BuyV2Colors.navy,
            icon: const Icon(Icons.forward_rounded),
          ),
        ),
      ),
    );
  }
}

class _ShopChatMessageContent extends StatelessWidget {
  const _ShopChatMessageContent({required this.message});

  final BuyV2ShopChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.kind == BuyV2ShopChatMessageKind.text) {
      return Text(
        message.body ?? '',
        style: context.buyBody.copyWith(fontSize: 12),
      );
    }
    final spec = message.kind.attachmentSpec;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 54, minWidth: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                spec.color.withValues(alpha: .16),
                Colors.white.withValues(alpha: .66),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: Icon(spec.icon, color: spec.color, size: 21),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.attachmentName ?? spec.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyBody.copyWith(fontSize: 11.5),
                    ),
                    if (message.attachmentDetail != null)
                      Text(
                        message.attachmentDetail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 9),
                      ),
                  ],
                ),
              ),
              Icon(
                message.kind == BuyV2ShopChatMessageKind.voice
                    ? Icons.play_arrow_rounded
                    : Icons.open_in_new_rounded,
                color: spec.color,
                size: 20,
              ),
            ],
          ),
        ),
        if (message.body != null && message.body!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(message.body!, style: context.buyBody.copyWith(fontSize: 11.5)),
        ],
      ],
    );
  }
}

class _ShopChatInlineAttachmentTray extends StatelessWidget {
  const _ShopChatInlineAttachmentTray({
    required this.capabilities,
    required this.presentation,
    required this.compact,
    required this.onSelected,
  });

  final BuyV2ShopChatCapabilities capabilities;
  final BuyV2ShopChatPresentation presentation;
  final bool compact;
  final ValueChanged<BuyV2ShopChatActionKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final actions = [
      if (capabilities.documents)
        const _AttachmentAction(
          BuyV2ShopChatActionKind.selectDocument,
          'Document',
          Icons.description_outlined,
          BuyV2Colors.royal,
        ),
      if (capabilities.camera)
        const _AttachmentAction(
          BuyV2ShopChatActionKind.captureImage,
          'Camera',
          Icons.photo_camera_outlined,
          BuyV2Colors.orange,
        ),
      if (capabilities.media)
        const _AttachmentAction(
          BuyV2ShopChatActionKind.selectMedia,
          'Photos & videos',
          Icons.photo_library_outlined,
          Color(0xFF7B2CBF),
        ),
      if (capabilities.productSharing)
        const _AttachmentAction(
          BuyV2ShopChatActionKind.shareProduct,
          'Product',
          Icons.shopping_bag_outlined,
          BuyV2Colors.orange,
        ),
      if (capabilities.orderSharing)
        const _AttachmentAction(
          BuyV2ShopChatActionKind.shareOrder,
          'Order',
          Icons.receipt_long_outlined,
          BuyV2Colors.green,
        ),
      if (capabilities.locationSharing)
        const _AttachmentAction(
          BuyV2ShopChatActionKind.shareLocation,
          'Location',
          Icons.location_on_outlined,
          Color(0xFF0F8B8D),
        ),
      if (capabilities.contactSharing)
        const _AttachmentAction(
          BuyV2ShopChatActionKind.shareContact,
          'Contact',
          Icons.person_outline_rounded,
          BuyV2Colors.navy,
        ),
    ];
    Widget actionTile(_AttachmentAction action) => Semantics(
      button: true,
      label: 'Share ${action.label}',
      excludeSemantics: true,
      onTap: () => onSelected(action.kind),
      child: InkWell(
        key: ValueKey('buy-shop-chat-attach-${action.kind.name}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => onSelected(action.kind),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(action.icon, color: action.color, size: 21),
            ),
            const SizedBox(height: 3),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.buyMeta.copyWith(fontSize: 8.5),
            ),
          ],
        ),
      ),
    );
    return Material(
      key: const ValueKey('buy-shop-chat-attachment-tray'),
      color: Colors.white,
      elevation: 8,
      child: compact
          ? SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                itemCount: actions.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return SizedBox(
                      width: 116,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: presentation.accent.withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              presentation.icon,
                              color: presentation.accent,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Share in this ${presentation.familyLabel} chat',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(
                                color: BuyV2Colors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox(
                    width: 72,
                    child: actionTile(actions[index - 1]),
                  );
                },
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: presentation.accent.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          presentation.icon,
                          color: presentation.accent,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share in this ${presentation.familyLabel} chat',
                              style: context.buyBody.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Choose what is relevant to this conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisExtent: 67,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: actions.length,
                    itemBuilder: (context, index) => actionTile(actions[index]),
                  ),
                ],
              ),
            ),
    );
  }
}

@immutable
class _AttachmentAction {
  const _AttachmentAction(this.kind, this.label, this.icon, this.color);

  final BuyV2ShopChatActionKind kind;
  final String label;
  final IconData icon;
  final Color color;
}

class _ShopChatInfoView extends StatefulWidget {
  const _ShopChatInfoView({
    super.key,
    required this.thread,
    required this.presentation,
    required this.navigationForward,
    required this.onBack,
    required this.onDispatch,
    required this.onOpenContext,
  });

  final BuyV2ShopChatThread thread;
  final BuyV2ShopChatPresentation presentation;
  final Widget? navigationForward;
  final VoidCallback onBack;
  final _ShopChatDispatch onDispatch;
  final VoidCallback? onOpenContext;

  @override
  State<_ShopChatInfoView> createState() => _ShopChatInfoViewState();
}

class _ShopChatInfoViewState extends State<_ShopChatInfoView> {
  bool _dispatching = false;
  BuyV2ShopChatActionKind? _activeAction;

  BuyV2ShopChatThread get thread => widget.thread;
  BuyV2ShopChatPresentation get presentation => widget.presentation;
  Widget? get navigationForward => widget.navigationForward;
  VoidCallback get onBack => widget.onBack;
  _ShopChatDispatch get onDispatch => widget.onDispatch;
  VoidCallback? get onOpenContext => widget.onOpenContext;

  @override
  Widget build(BuildContext context) {
    final shared = thread.messages
        .where((message) => message.kind != BuyV2ShopChatMessageKind.text)
        .toList(growable: false);
    return Semantics(
      key: const ValueKey('buy-shop-chat-info'),
      container: true,
      label: '${thread.title} information',
      child: ColoredBox(
        color: const Color(0xFFF6F6FA),
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 66),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  bottom: BorderSide(color: BuyV2Colors.line),
                ),
                gradient: LinearGradient(
                  colors: [
                    presentation.accent.withValues(alpha: .07),
                    Colors.white,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('buy-shop-chat-info-back'),
                    tooltip: 'Back to conversation',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: presentation.accent.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      presentation.icon,
                      color: presentation.accent,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${presentation.familyLabel} Chat info',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyTitle.copyWith(fontSize: 18),
                        ),
                        Text(
                          thread.contextTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyMeta.copyWith(fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            if (_activeAction case final action?)
              Semantics(
                key: const ValueKey('buy-shop-chat-info-progress'),
                container: true,
                liveRegion: true,
                label: action.inProgressMessage,
                child: const LinearProgressIndicator(minHeight: 3),
              ),
            ?navigationForward,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                children: [
                  Center(child: _ShopChatAvatar(thread: thread, size: 78)),
                  const SizedBox(height: 11),
                  Text(
                    thread.title,
                    textAlign: TextAlign.center,
                    style: context.buyTitle,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${presentation.familyLabel} · ${thread.participantKind.customerLabel}',
                    textAlign: TextAlign.center,
                    style: context.buyMeta,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (thread.capabilities.voiceCall)
                        _ShopChatInfoAction(
                          keyName: 'voice-call',
                          icon: Icons.call_outlined,
                          label: 'Voice',
                          onTap: _dispatching
                              ? null
                              : () => _dispatchInfoAction(
                                  context,
                                  BuyV2ShopChatActionKind.startVoiceCall,
                                ),
                        ),
                      if (thread.capabilities.videoCall) ...[
                        const SizedBox(width: 10),
                        _ShopChatInfoAction(
                          keyName: 'video-call',
                          icon: Icons.videocam_outlined,
                          label: 'Video',
                          onTap: _dispatching
                              ? null
                              : () => _dispatchInfoAction(
                                  context,
                                  BuyV2ShopChatActionKind.startVideoCall,
                                ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ShopChatInfoCard(
                    title: thread.contextTitle,
                    subtitle: thread.contextDetail,
                    icon: thread.icon,
                    trailing: onOpenContext == null || _dispatching
                        ? null
                        : 'Open',
                    onTap: _dispatching ? null : onOpenContext,
                  ),
                  const SizedBox(height: 10),
                  _ShopChatInfoCard(
                    title: 'Media, links and documents',
                    subtitle: shared.isEmpty
                        ? 'Nothing shared yet'
                        : '${shared.length} shared item${shared.length == 1 ? '' : 's'}',
                    icon: Icons.perm_media_outlined,
                  ),
                  const SizedBox(height: 10),
                  _ShopChatInfoCard(
                    title: 'Notifications',
                    subtitle: 'Manage alerts for this conversation',
                    icon: Icons.notifications_outlined,
                    trailing: _dispatching ? null : 'Manage',
                    onTap: _dispatching
                        ? null
                        : () => _dispatchInfoAction(
                            context,
                            BuyV2ShopChatActionKind.manageNotifications,
                          ),
                  ),
                  const SizedBox(height: 10),
                  _ShopChatInfoCard(
                    title: 'Safety and support',
                    subtitle: 'Block, report or ask MoolSocial for help',
                    icon: Icons.shield_outlined,
                    trailing: _dispatching ? null : 'Open',
                    onTap: _dispatching
                        ? null
                        : () => _dispatchInfoAction(
                            context,
                            BuyV2ShopChatActionKind.openSafety,
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

  Future<void> _dispatchInfoAction(
    BuildContext context,
    BuyV2ShopChatActionKind kind,
  ) async {
    if (_dispatching) return;
    setState(() {
      _dispatching = true;
      _activeAction = kind;
    });
    final result = await onDispatch(
      BuyV2ShopChatAction(kind: kind, threadId: thread.id),
    );
    if (!context.mounted) return;
    setState(() {
      _dispatching = false;
      _activeAction = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    if (result.customerMessage == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.customerMessage!),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

class _ShopChatInfoAction extends StatelessWidget {
  const _ShopChatInfoAction({
    required this.keyName,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: 76,
      height: 68,
      child: OutlinedButton(
        key: ValueKey('buy-shop-chat-info-$keyName'),
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: const BorderSide(color: BuyV2Colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? BuyV2Colors.navy : BuyV2Colors.muted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: context.buyMeta.copyWith(
                color: enabled ? BuyV2Colors.navy : BuyV2Colors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopChatInfoCard extends StatelessWidget {
  const _ShopChatInfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      child: ListTile(
        minTileHeight: 66,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: BuyV2Colors.navy),
        title: Text(title, style: context.buyBody),
        subtitle: Text(subtitle, style: context.buyMeta),
        trailing: trailing == null
            ? null
            : Text(
                trailing!,
                style: context.buyMeta.copyWith(
                  color: BuyV2Colors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
        onTap: onTap,
      ),
    );
  }
}

@immutable
class _ShopChatAttachmentSpec {
  const _ShopChatAttachmentSpec(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

extension on BuyV2ShopChatParticipantKind {
  String get customerLabel => switch (this) {
    BuyV2ShopChatParticipantKind.retailer => 'Retail partner',
    BuyV2ShopChatParticipantKind.wholesaler => 'Wholesale partner',
    BuyV2ShopChatParticipantKind.manufacturer => 'Manufacturer',
    BuyV2ShopChatParticipantKind.orderSupport => 'Order conversation',
    BuyV2ShopChatParticipantKind.offerSupport => 'Offer conversation',
    BuyV2ShopChatParticipantKind.restaurant => 'Restaurant partner',
    BuyV2ShopChatParticipantKind.tableDesk => 'Reservation desk',
    BuyV2ShopChatParticipantKind.travelPartner => 'Travel partner',
    BuyV2ShopChatParticipantKind.doctorDesk => 'Care provider',
    BuyV2ShopChatParticipantKind.medicineDesk => 'Medicine support',
    BuyV2ShopChatParticipantKind.salonDesk => 'Salon partner',
    BuyV2ShopChatParticipantKind.workOpportunity => 'Work opportunity',
    BuyV2ShopChatParticipantKind.workspaceSupport => 'Workspace support',
  };
}

extension on BuyV2ShopChatMessageKind {
  String get customerLabel => switch (this) {
    BuyV2ShopChatMessageKind.text => 'message',
    BuyV2ShopChatMessageKind.image => 'photo',
    BuyV2ShopChatMessageKind.video => 'video',
    BuyV2ShopChatMessageKind.document => 'document',
    BuyV2ShopChatMessageKind.voice => 'voice message',
    BuyV2ShopChatMessageKind.product => 'product',
    BuyV2ShopChatMessageKind.order => 'order',
    BuyV2ShopChatMessageKind.location => 'location',
    BuyV2ShopChatMessageKind.contact => 'contact',
  };

  _ShopChatAttachmentSpec get attachmentSpec => switch (this) {
    BuyV2ShopChatMessageKind.text => const _ShopChatAttachmentSpec(
      'Message',
      Icons.chat_bubble_outline_rounded,
      BuyV2Colors.navy,
    ),
    BuyV2ShopChatMessageKind.image => const _ShopChatAttachmentSpec(
      'Photo',
      Icons.image_outlined,
      BuyV2Colors.orange,
    ),
    BuyV2ShopChatMessageKind.video => const _ShopChatAttachmentSpec(
      'Video',
      Icons.play_circle_outline_rounded,
      Color(0xFF7B2CBF),
    ),
    BuyV2ShopChatMessageKind.document => const _ShopChatAttachmentSpec(
      'Document',
      Icons.description_outlined,
      BuyV2Colors.royal,
    ),
    BuyV2ShopChatMessageKind.voice => const _ShopChatAttachmentSpec(
      'Voice message',
      Icons.graphic_eq_rounded,
      BuyV2Colors.green,
    ),
    BuyV2ShopChatMessageKind.product => const _ShopChatAttachmentSpec(
      'Product',
      Icons.shopping_bag_outlined,
      BuyV2Colors.orange,
    ),
    BuyV2ShopChatMessageKind.order => const _ShopChatAttachmentSpec(
      'Order',
      Icons.receipt_long_outlined,
      BuyV2Colors.green,
    ),
    BuyV2ShopChatMessageKind.location => const _ShopChatAttachmentSpec(
      'Location',
      Icons.location_on_outlined,
      Color(0xFF0F8B8D),
    ),
    BuyV2ShopChatMessageKind.contact => const _ShopChatAttachmentSpec(
      'Contact',
      Icons.person_outline_rounded,
      BuyV2Colors.navy,
    ),
  };
}

extension on BuyV2ShopChatDeliveryState {
  String get customerLabel => switch (this) {
    BuyV2ShopChatDeliveryState.pending => 'Sending',
    BuyV2ShopChatDeliveryState.sent => 'Sent',
    BuyV2ShopChatDeliveryState.delivered => 'Delivered',
    BuyV2ShopChatDeliveryState.read => 'Read',
    BuyV2ShopChatDeliveryState.failed => 'Not sent',
  };

  IconData get deliveryIcon => switch (this) {
    BuyV2ShopChatDeliveryState.pending => Icons.schedule_rounded,
    BuyV2ShopChatDeliveryState.sent => Icons.check_rounded,
    BuyV2ShopChatDeliveryState.delivered => Icons.done_all_rounded,
    BuyV2ShopChatDeliveryState.read => Icons.done_all_rounded,
    BuyV2ShopChatDeliveryState.failed => Icons.error_outline_rounded,
  };
}

extension on BuyV2ShopChatActionKind {
  String get inProgressMessage => switch (this) {
    BuyV2ShopChatActionKind.sendText => 'Sending message',
    BuyV2ShopChatActionKind.startVoiceCall => 'Starting voice call',
    BuyV2ShopChatActionKind.startVideoCall => 'Starting video call',
    BuyV2ShopChatActionKind.recordVoice => 'Starting voice message',
    BuyV2ShopChatActionKind.openAttachment => 'Opening shared item',
    BuyV2ShopChatActionKind.forwardMessage => 'Forwarding message',
    BuyV2ShopChatActionKind.reactToMessage => 'Liking message',
    BuyV2ShopChatActionKind.manageNotifications =>
      'Opening notification settings',
    BuyV2ShopChatActionKind.openSafety => 'Opening safety and support',
    BuyV2ShopChatActionKind.captureImage ||
    BuyV2ShopChatActionKind.selectMedia ||
    BuyV2ShopChatActionKind.selectDocument ||
    BuyV2ShopChatActionKind.shareProduct ||
    BuyV2ShopChatActionKind.shareOrder ||
    BuyV2ShopChatActionKind.shareLocation ||
    BuyV2ShopChatActionKind.shareContact => 'Adding item to conversation',
    _ => 'Completing Chat action',
  };

  String get unexpectedFailureMessage => switch (this) {
    BuyV2ShopChatActionKind.sendText => 'Message wasn’t sent. Try again.',
    BuyV2ShopChatActionKind.startVoiceCall ||
    BuyV2ShopChatActionKind.startVideoCall =>
      'The call didn’t start. Try again.',
    BuyV2ShopChatActionKind.openAttachment =>
      'That shared item couldn’t open. Try again.',
    BuyV2ShopChatActionKind.forwardMessage =>
      'The message wasn’t forwarded. Try again.',
    BuyV2ShopChatActionKind.manageNotifications =>
      'Notification settings couldn’t open. Try again.',
    BuyV2ShopChatActionKind.openSafety =>
      'Safety and support couldn’t open. Try again.',
    BuyV2ShopChatActionKind.reply ||
    BuyV2ShopChatActionKind.copyMessage ||
    BuyV2ShopChatActionKind.reactToMessage =>
      'That message action didn’t complete. Try again.',
    BuyV2ShopChatActionKind.captureImage ||
    BuyV2ShopChatActionKind.selectMedia ||
    BuyV2ShopChatActionKind.selectDocument ||
    BuyV2ShopChatActionKind.recordVoice ||
    BuyV2ShopChatActionKind.shareProduct ||
    BuyV2ShopChatActionKind.shareOrder ||
    BuyV2ShopChatActionKind.shareLocation ||
    BuyV2ShopChatActionKind.shareContact =>
      'That item wasn’t added. Try again.',
  };
}

extension on BuyV2OrderStatus {
  String get customerLabel => switch (this) {
    BuyV2OrderStatus.preparing => 'Preparing',
    BuyV2OrderStatus.confirmed => 'Confirmed',
    BuyV2OrderStatus.dispatched => 'Dispatched',
    BuyV2OrderStatus.arriving => 'Arriving',
    BuyV2OrderStatus.delivered => 'Delivered',
  };
}
