import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/mool_design_system.dart';
import 'social_v2_design.dart';

@immutable
class Screen04Choice {
  const Screen04Choice(this.id, this.label, {this.attributionAsset});

  final String id;
  final String label;
  final String? attributionAsset;
}

@immutable
class Screen04World {
  const Screen04World({
    required this.id,
    required this.label,
    required this.tagline,
    required this.prompt,
    required this.choices,
  });

  final String id;
  final String label;
  final String tagline;
  final String prompt;
  final List<Screen04Choice> choices;
}

const screen04Worlds = <Screen04World>[
  Screen04World(
    id: 'social',
    label: 'Social',
    tagline: 'Connect, create and earn',
    prompt: 'Search videos, reels, people or posts',
    choices: [
      Screen04Choice(
        'videos',
        'Home',
        attributionAsset: 'assets/prototype/provider-youtube.svg',
      ),
      Screen04Choice(
        'shorts',
        'Shorts',
        attributionAsset: 'assets/prototype/provider-youtube.svg',
      ),
      Screen04Choice('create', 'Create'),
      Screen04Choice('feed', 'Feed'),
    ],
  ),
  Screen04World(
    id: 'buy',
    label: 'Shop',
    tagline: 'Retail and wholesale, in one place',
    prompt: 'Search products, wholesale or orders',
    choices: [
      Screen04Choice('shop', 'Products'),
      Screen04Choice('wholesale', 'Wholesale'),
      Screen04Choice('orders', 'Orders'),
    ],
  ),
  Screen04World(
    id: 'eat',
    label: 'Food',
    tagline: 'Food and tables around you',
    prompt: 'Search restaurants, food or tables',
    choices: [
      Screen04Choice('order-food', 'Order Food'),
      Screen04Choice('book-table', 'Book Table'),
    ],
  ),
  Screen04World(
    id: 'ride',
    label: 'Travel',
    tagline: 'Choose how you want to travel',
    prompt: 'Choose a bike, auto, cab or bus',
    choices: [
      Screen04Choice('bike', 'Bike'),
      Screen04Choice('auto', 'Auto'),
      Screen04Choice('cab', 'Cab'),
      Screen04Choice('bus', 'Bus'),
    ],
  ),
  Screen04World(
    id: 'book',
    label: 'Care',
    tagline: 'Trusted services, ready to book',
    prompt: 'Find doctors, medicine or salons',
    choices: [
      Screen04Choice('doctor', 'Doctor'),
      Screen04Choice('medicine', 'Medicine'),
      Screen04Choice('salon', 'Salon'),
    ],
  ),
  Screen04World(
    id: 'work',
    label: 'Work',
    tagline: 'Find opportunities and manage work',
    prompt: 'Find nearby work or open your workspace',
    choices: [
      Screen04Choice('earn-today', 'Earn Today'),
      Screen04Choice('workspace', 'Workspace'),
    ],
  ),
];

Screen04World screen04World(String id) => screen04Worlds.firstWhere(
  (world) => world.id == id,
  orElse: () => screen04Worlds.first,
);

class Screen04Header extends StatelessWidget {
  const Screen04Header({
    required this.area,
    required this.prompt,
    required this.immersive,
    required this.onHome,
    required this.onArea,
    required this.onChat,
    required this.onNotifications,
    required this.onProfile,
    required this.onSearch,
    required this.onScan,
    required this.onVoice,
    this.showChat = true,
    super.key,
  });

  final String area;
  final String prompt;
  final bool immersive;
  final VoidCallback onHome;
  final VoidCallback onArea;
  final VoidCallback onChat;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onSearch;
  final VoidCallback onScan;
  final VoidCallback onVoice;
  final bool showChat;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SocialV2Colors.navy, Color(0xFF00006A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x2B000080),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          immersive ? 4 : 9,
          12,
          immersive ? 4 : 11,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                if (showChat) ...[
                  _HeaderRoundButton(
                    key: const Key('social-global-chat'),
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Open Chat',
                    onPressed: onChat,
                  ),
                  const SizedBox(width: 6),
                ],
                _HeaderRoundButton(
                  key: const Key('screen04-notifications'),
                  icon: Icons.notifications_none_rounded,
                  label: 'Open notifications',
                  showDot: true,
                  onPressed: onNotifications,
                ),
                const SizedBox(width: 6),
                _HeaderRoundButton(
                  key: const Key('screen04-profile'),
                  icon: Icons.person_outline_rounded,
                  label: 'Open profile and account',
                  onPressed: onProfile,
                ),
              ],
            ),
            if (!immersive) ...[
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: 'Services near $area',
                  child: InkWell(
                    key: const Key('screen04-area'),
                    onTap: onArea,
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxWidth: 210,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Services near',
                                  style: TextStyle(
                                    color: Color(0xBFFFFFFF),
                                    fontSize: 10,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  area,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: const Color(0xFFF9F9FD),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        key: const Key('screen04-search'),
                        onTap: onSearch,
                        borderRadius: BorderRadius.circular(14),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: SocialV2Colors.navy,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    prompt,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF4D5066),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _HeaderSquareButton(
                    key: const Key('screen04-scan'),
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan a code',
                    onPressed: onScan,
                  ),
                  const SizedBox(width: 6),
                  _HeaderSquareButton(
                    key: const Key('screen04-voice'),
                    icon: Icons.mic_none_rounded,
                    label: 'Use voice search',
                    onPressed: onVoice,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Screen04VideoHeader extends StatefulWidget {
  const Screen04VideoHeader({
    required this.onHome,
    required this.onChat,
    required this.onNotifications,
    required this.onProfile,
    required this.onQueryChanged,
    this.initialQuery = '',
    super.key,
  });

  final VoidCallback onHome;
  final VoidCallback onChat;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final ValueChanged<String> onQueryChanged;
  final String initialQuery;

  @override
  State<Screen04VideoHeader> createState() => _Screen04VideoHeaderState();
}

class _Screen04VideoHeaderState extends State<Screen04VideoHeader> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialQuery,
  );
  final FocusNode _focusNode = FocusNode();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNode.requestFocus(),
      );
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SocialV2Colors.navy, Color(0xFF00006A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000080),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 5, 9, 6),
        child: Column(
          children: [
            Row(
              children: [
                _HeaderRoundButton(
                  key: const Key('screen04-video-search-toggle'),
                  icon: Icons.search_rounded,
                  label: 'Search videos',
                  onPressed: _toggleSearch,
                ),
                const SizedBox(width: 6),
                const Spacer(),
                _HeaderRoundButton(
                  key: const Key('social-global-chat'),
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Open Chat',
                  onPressed: widget.onChat,
                ),
                const SizedBox(width: 5),
                _HeaderRoundButton(
                  key: const Key('screen04-notifications'),
                  icon: Icons.notifications_none_rounded,
                  label: 'Open notifications',
                  showDot: true,
                  onPressed: widget.onNotifications,
                ),
                const SizedBox(width: 5),
                _HeaderRoundButton(
                  key: const Key('screen04-profile'),
                  icon: Icons.person_outline_rounded,
                  label: 'Open profile and account',
                  onPressed: widget.onProfile,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              child: !_expanded
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('screen04-video-search-field'),
                              controller: _controller,
                              focusNode: _focusNode,
                              textInputAction: TextInputAction.search,
                              onChanged: widget.onQueryChanged,
                              onSubmitted: widget.onQueryChanged,
                              style: const TextStyle(
                                color: SocialV2Colors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search videos',
                                hintStyle: const TextStyle(fontSize: 12),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(99),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: _controller.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        onPressed: () {
                                          _controller.clear();
                                          widget.onQueryChanged('');
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _HeaderRoundButton(
                            icon: Icons.search_rounded,
                            label: 'Search',
                            onPressed: () =>
                                widget.onQueryChanged(_controller.text.trim()),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRoundButton extends StatelessWidget {
  const _HeaderRoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.showDot = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: label,
          onPressed: onPressed,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white10,
            side: const BorderSide(color: Colors.white24),
            shape: const CircleBorder(),
          ),
          icon: Icon(icon, size: 21),
        ),
        if (showDot)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: SocialV2Colors.saffron,
                border: Border.all(color: SocialV2Colors.navy, width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderSquareButton extends StatelessWidget {
  const _HeaderSquareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white10,
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 21),
    );
  }
}

class Screen04ContextTabs extends StatelessWidget {
  const Screen04ContextTabs({
    required this.world,
    required this.choice,
    required this.onChoice,
    super.key,
  });

  final Screen04World world;
  final String choice;
  final ValueChanged<String> onChoice;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('screen04-context-tabs'),
      height: MoolLocalNavigationTokens.railHeight,
      child: MoolLocalNavigationRail(
        key: const Key('screen04-choice-ribbon'),
        familyId: 'social',
        surfaceTone: MoolLocalNavigationSurfaceTone.media,
        semanticLabel: '${world.label} options',
        activeId: choice,
        actions: [
          for (final item in world.choices)
            MoolLocalNavigationAction(
              keyName: 'screen04-rail-${item.id}',
              id: item.id,
              label: item.label,
              semanticLabel: item.attributionAsset == null
                  ? item.label
                  : 'YouTube ${item.label}',
              icon: switch (item.id) {
                'shorts' => Icons.play_circle_outline_rounded,
                'videos' => Icons.home_outlined,
                'feed' => Icons.dynamic_feed_outlined,
                'create' => Icons.add_circle_outline_rounded,
                _ => Icons.circle_outlined,
              },
              iconAsset: item.attributionAsset,
              onPressed: item.id == choice
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChoice(item.id);
                    },
            ),
        ],
      ),
    );
  }
}

@immutable
class Screen04CardSpec {
  const Screen04CardSpec(this.title, this.detail, this.tone);

  final String title;
  final String detail;
  final Color tone;
}

@immutable
class Screen04ContentSpec {
  const Screen04ContentSpec({
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.primary,
    required this.section,
    required this.note,
    required this.cards,
    required this.chips,
    required this.actions,
    required this.gradientEnd,
  });

  final String eyebrow;
  final String title;
  final String detail;
  final String primary;
  final String section;
  final String note;
  final List<Screen04CardSpec> cards;
  final List<String> chips;
  final List<String> actions;
  final Color gradientEnd;
}

const _saffron = SocialV2Colors.saffron;
const _green = SocialV2Colors.green;
const _navy = SocialV2Colors.navy;

const screen04Content = <String, Screen04ContentSpec>{
  'grocery': Screen04ContentSpec(
    eyebrow: 'Shop · Products',
    title: 'Everyday essentials, nearby',
    detail:
        'Compare fresh items and household needs from stores serving your area.',
    primary: 'Shop Grocery',
    section: 'Shop your way',
    note: 'Availability for your area',
    cards: [
      Screen04CardSpec('Fresh today', 'Fruit, vegetables and dairy', _green),
      Screen04CardSpec(
        'Monthly needs',
        'Staples and household packs',
        _saffron,
      ),
      Screen04CardSpec('Nearby stores', 'Compare price and delivery', _navy),
    ],
    chips: ['Fresh', 'Value packs', 'Fast delivery'],
    actions: ['Compare', 'Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF0A5E5A),
  ),
  'categories': Screen04ContentSpec(
    eyebrow: 'Shop · Categories',
    title: 'Find the right aisle faster',
    detail: 'Browse personal care, home, electronics and daily needs.',
    primary: 'Browse Categories',
    section: 'Popular categories',
    note: 'Products serving your area',
    cards: [
      Screen04CardSpec(
        'Home & kitchen',
        'Useful picks for every room',
        _saffron,
      ),
      Screen04CardSpec('Personal care', 'Daily care and wellness', _green),
      Screen04CardSpec('Electronics', 'Compare useful devices', _navy),
    ],
    chips: ['Home', 'Care', 'Electronics'],
    actions: ['Compare', 'Save', 'Chat'],
    gradientEnd: Color(0xFF2626A5),
  ),
  'medicine': Screen04ContentSpec(
    eyebrow: 'Care · Medicine',
    title: 'Health needs with clear steps',
    detail:
        'Find medicines and wellness essentials, with prescription checks when needed.',
    primary: 'Find Medicine',
    section: 'Health essentials',
    note: 'Prescription rules are shown before checkout',
    cards: [
      Screen04CardSpec(
        'Upload prescription',
        'Add a clear photo for eligible items',
        _green,
      ),
      Screen04CardSpec('Wellness', 'Everyday care and nutrition', _saffron),
    ],
    chips: ['Medicine', 'Wellness', 'Past orders'],
    actions: ['Save', 'Chat', 'Help'],
    gradientEnd: Color(0xFF126B57),
  ),
  'basket': Screen04ContentSpec(
    eyebrow: 'Shop · Basket',
    title: 'Your basket is ready',
    detail:
        'Check quantities, delivery choices and the full price before you continue.',
    primary: 'Open Basket',
    section: 'Basket choices',
    note: 'Nothing is ordered until you confirm',
    cards: [
      Screen04CardSpec(
        'Saved for later',
        'Items you want to revisit',
        _saffron,
      ),
      Screen04CardSpec('Family basket', 'Coordinate household needs', _green),
    ],
    chips: ['Items', 'Delivery', 'Savings'],
    actions: ['Save', 'Family', 'Chat'],
    gradientEnd: Color(0xFF4A2572),
  ),
  'order-food': Screen04ContentSpec(
    eyebrow: 'Food · Order Food',
    title: 'Good food around you',
    detail: 'Explore trusted kitchens with clear delivery time and price.',
    primary: 'Find Food',
    section: 'What are you craving?',
    note: 'Serving your selected area',
    cards: [
      Screen04CardSpec(
        'Quick meals',
        'Popular choices with faster delivery',
        _saffron,
      ),
      Screen04CardSpec('Top rated', 'Loved by nearby customers', _green),
      Screen04CardSpec('Pure veg', 'Vegetarian kitchens and dishes', _navy),
    ],
    chips: ['Quick', 'Top rated', 'Pure veg'],
    actions: ['Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF8D3E00),
  ),
  'book-table': Screen04ContentSpec(
    eyebrow: 'Food · Book Table',
    title: 'A table for your moment',
    detail:
        'Choose a restaurant, time and party size before requesting a table.',
    primary: 'Find a Table',
    section: 'Plan your visit',
    note: 'The restaurant confirms availability',
    cards: [
      Screen04CardSpec('Tonight', 'Tables available this evening', _saffron),
      Screen04CardSpec('This weekend', 'Plan ahead with more choices', _green),
    ],
    chips: ['2 people', 'Family', 'Outdoor'],
    actions: ['Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF693C13),
  ),
  'tiffin': Screen04ContentSpec(
    eyebrow: 'Food · Tiffin',
    title: 'Homestyle meals, regularly',
    detail:
        'Compare meal plans, delivery days and pause rules before subscribing.',
    primary: 'Explore Tiffin',
    section: 'Meal plans',
    note: 'Flexible plans serving your area',
    cards: [
      Screen04CardSpec(
        'Lunch plans',
        'Weekday meals delivered near noon',
        _saffron,
      ),
      Screen04CardSpec('Dinner plans', 'Evening meals for home', _green),
    ],
    chips: ['Weekly', 'Monthly', 'Pause anytime'],
    actions: ['Save', 'Chat', 'Family'],
    gradientEnd: Color(0xFF5F4A00),
  ),
  'bike': Screen04ContentSpec(
    eyebrow: 'Travel · Bike',
    title: 'A quick ride across town',
    detail: 'Set your destination to see nearby bikes and an estimated fare.',
    primary: 'Book a Bike',
    section: 'Plan this ride',
    note: 'Fare and rider details appear before booking',
    cards: [
      Screen04CardSpec(
        'Set destination',
        'Choose where you want to go',
        _green,
      ),
      Screen04CardSpec('Saved places', 'Home, work and recent stops', _saffron),
    ],
    chips: ['Fast pickup', 'Helmet included', 'Fare first'],
    actions: ['Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF0E6161),
  ),
  'auto': Screen04ContentSpec(
    eyebrow: 'Travel · Auto',
    title: 'An auto when you need one',
    detail: 'Choose your destination and compare the fare before booking.',
    primary: 'Book an Auto',
    section: 'Plan this ride',
    note: 'Pickup options for your area',
    cards: [
      Screen04CardSpec('Set destination', 'See fare and arrival time', _green),
      Screen04CardSpec(
        'Ride for someone',
        'Share pickup details clearly',
        _saffron,
      ),
    ],
    chips: ['Nearby', 'Fare first', 'Share trip'],
    actions: ['Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF496900),
  ),
  'cab': Screen04ContentSpec(
    eyebrow: 'Travel · Cab',
    title: 'More room for the journey',
    detail: 'Compare cab sizes, arrival time and fare for your trip.',
    primary: 'Book a Cab',
    section: 'Choose your trip',
    note: 'Vehicle details appear before booking',
    cards: [
      Screen04CardSpec('City ride', 'Comfortable rides around town', _saffron),
      Screen04CardSpec('Outstation', 'Plan a longer journey', _green),
    ],
    chips: ['Mini', 'Sedan', 'Larger cab'],
    actions: ['Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF36364A),
  ),
  'bus': Screen04ContentSpec(
    eyebrow: 'Travel · Bus',
    title: 'Plan your bus journey',
    detail: 'Choose your route and travel date before viewing available buses.',
    primary: 'Find Buses',
    section: 'Plan this trip',
    note: 'Routes, seats and fares appear before booking',
    cards: [
      Screen04CardSpec('Choose route', 'Set departure and destination', _green),
      Screen04CardSpec('Travel date', 'Pick when you want to leave', _saffron),
    ],
    chips: ['Route first', 'Fare first', 'Seat choice'],
    actions: ['Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF213A62),
  ),
  'get-done': Screen04ContentSpec(
    eyebrow: 'Care · Get It Done',
    title: 'Trusted help for everyday tasks',
    detail:
        'Choose the job, time and price range before requesting a professional.',
    primary: 'Find a Service',
    section: 'Popular services',
    note: 'Availability for your area',
    cards: [
      Screen04CardSpec(
        'Home repair',
        'Electrician, plumber and more',
        _saffron,
      ),
      Screen04CardSpec('Laundry', 'Pickup, care and return options', _green),
      Screen04CardSpec('Cleaning', 'Home and office cleaning', _navy),
    ],
    chips: ['Home', 'Repair', 'Care'],
    actions: ['Book', 'Proof', 'Chat'],
    gradientEnd: Color(0xFF315A3A),
  ),
  'doctor': Screen04ContentSpec(
    eyebrow: 'Care · Doctor',
    title: 'Find the care you need',
    detail: 'Browse doctors by speciality, time and consultation type.',
    primary: 'Find a Doctor',
    section: 'Start with a need',
    note: 'Doctor details and fees shown before booking',
    cards: [
      Screen04CardSpec('General care', 'Common health concerns', _green),
      Screen04CardSpec(
        'Women’s health',
        'Browse available specialists',
        _saffron,
      ),
      Screen04CardSpec('Child care', 'Find nearby paediatric care', _navy),
    ],
    chips: ['In clinic', 'Video', 'Today'],
    actions: ['Save', 'Chat', 'Help'],
    gradientEnd: Color(0xFF006B72),
  ),
  'salon': Screen04ContentSpec(
    eyebrow: 'Care · Salon',
    title: 'Care that fits your day',
    detail:
        'Choose a service, professional and time with the price shown first.',
    primary: 'Book a Salon',
    section: 'Popular appointments',
    note: 'At-home and nearby options',
    cards: [
      Screen04CardSpec('Hair care', 'Cuts, styling and treatments', _saffron),
      Screen04CardSpec('Grooming', 'Everyday personal care', _green),
    ],
    chips: ['Nearby', 'At home', 'Price first'],
    actions: ['Save', 'Chat', 'Share'],
    gradientEnd: Color(0xFF71325A),
  ),
  'recharge': Screen04ContentSpec(
    eyebrow: 'Pay · Recharge',
    title: 'Recharge without the guesswork',
    detail: 'Choose a number and plan, then check every detail before paying.',
    primary: 'Start Recharge',
    section: 'Quick choices',
    note: 'Plan price and validity shown first',
    cards: [
      Screen04CardSpec('Mobile', 'Prepaid and postpaid numbers', _saffron),
      Screen04CardSpec('DTH', 'Find your operator and plan', _green),
    ],
    chips: ['Mobile', 'DTH', 'Recent'],
    actions: ['Save', 'Help'],
    gradientEnd: Color(0xFF193F7A),
  ),
  'bills': Screen04ContentSpec(
    eyebrow: 'Pay · Bills',
    title: 'Keep household bills together',
    detail:
        'Find the biller, confirm the account and check the amount before paying.',
    primary: 'Pay a Bill',
    section: 'Bill categories',
    note: 'Nothing is paid until you confirm',
    cards: [
      Screen04CardSpec('Electricity', 'Find your board and account', _saffron),
      Screen04CardSpec('Water', 'Check supported local billers', _green),
      Screen04CardSpec('Gas', 'Pay eligible gas bills', _navy),
    ],
    chips: ['Electricity', 'Water', 'Gas'],
    actions: ['Save', 'Help'],
    gradientEnd: Color(0xFF5D4216),
  ),
  'scan-pay': Screen04ContentSpec(
    eyebrow: 'Pay · Scan & Pay',
    title: 'Scan, check, then pay',
    detail:
        'Read a code and confirm the recipient and amount before continuing.',
    primary: 'Scan a Code',
    section: 'Other ways to pay',
    note: 'Recipient details appear before payment',
    cards: [
      Screen04CardSpec('Enter UPI ID', 'Type and check the recipient', _green),
      Screen04CardSpec('Choose a contact', 'Pay someone you know', _saffron),
    ],
    chips: ['Scan', 'UPI ID', 'Contact'],
    actions: ['Scan', 'Help'],
    gradientEnd: Color(0xFF00674D),
  ),
  'receipts': Screen04ContentSpec(
    eyebrow: 'Pay · Receipts',
    title: 'Your payments, easy to find',
    detail:
        'Open a payment to see its amount, recipient and reference details.',
    primary: 'View Receipts',
    section: 'Find a receipt',
    note: 'Recent payment records',
    cards: [
      Screen04CardSpec('Recent', 'Your latest payment records', _saffron),
      Screen04CardSpec('Search receipts', 'Find by name or amount', _green),
    ],
    chips: ['Recent', 'Bills', 'Recharges'],
    actions: ['Save', 'Share', 'Help'],
    gradientEnd: Color(0xFF38386D),
  ),
  'earn-today': Screen04ContentSpec(
    eyebrow: 'Work · Earn Today',
    title: 'Work that fits today',
    detail:
        'See nearby opportunities with earnings, time and requirements up front.',
    primary: 'Find Work',
    section: 'Nearby opportunities',
    note: 'Requirements shown before you apply',
    cards: [
      Screen04CardSpec('Short shifts', 'Flexible work available today', _green),
      Screen04CardSpec(
        'Skilled work',
        'Opportunities matching your skills',
        _saffron,
      ),
    ],
    chips: ['Today', 'Nearby', 'Best match'],
    actions: ['Apply', 'Proof', 'Save'],
    gradientEnd: Color(0xFF27601E),
  ),
  'delivery': Screen04ContentSpec(
    eyebrow: 'Work · Delivery',
    title: 'Delivery work, clearly explained',
    detail: 'See service area, expected time and earnings before accepting.',
    primary: 'View Deliveries',
    section: 'Delivery choices',
    note: 'Pickup and drop details shown first',
    cards: [
      Screen04CardSpec(
        'Available now',
        'Nearby delivery opportunities',
        _saffron,
      ),
      Screen04CardSpec('Scheduled', 'Plan work for later', _green),
    ],
    chips: ['Nearby', 'Earnings first', 'Proof'],
    actions: ['Accept', 'Proof', 'Chat'],
    gradientEnd: Color(0xFF5D4D00),
  ),
  'onboard': Screen04ContentSpec(
    eyebrow: 'Work · Onboard',
    title: 'Get ready to earn',
    detail:
        'Complete your profile, skills and required documents at your pace.',
    primary: 'Continue Setup',
    section: 'Your steps',
    note: 'You can save and return',
    cards: [
      Screen04CardSpec('Work profile', 'Add skills and availability', _green),
      Screen04CardSpec('Documents', 'See what is required and why', _saffron),
    ],
    chips: ['Profile', 'Skills', 'Documents'],
    actions: ['Apply', 'Proof', 'Chat'],
    gradientEnd: Color(0xFF455B1A),
  ),
  'verify': Screen04ContentSpec(
    eyebrow: 'Work · Verify',
    title: 'Build trust for better work',
    detail: 'See each required check, why it matters and what you need.',
    primary: 'Start Verification',
    section: 'Verification choices',
    note: 'Your documents stay protected',
    cards: [
      Screen04CardSpec('Identity', 'Confirm who you are', _green),
      Screen04CardSpec('Skills', 'Add proof of your work', _saffron),
    ],
    chips: ['Identity', 'Skills', 'Trust'],
    actions: ['Apply', 'Proof', 'Save'],
    gradientEnd: Color(0xFF056559),
  ),
  'workspace': Screen04ContentSpec(
    eyebrow: 'Work · Workspace',
    title: 'Manage your work in one place',
    detail: 'Track active jobs, earnings, documents and support.',
    primary: 'Open Workspace',
    section: 'Workspace shortcuts',
    note: 'Your current work activity',
    cards: [
      Screen04CardSpec(
        'Active work',
        'Jobs in progress and next steps',
        _saffron,
      ),
      Screen04CardSpec('Earnings', 'See completed work and payouts', _green),
      Screen04CardSpec('Documents', 'Manage your work documents', _navy),
    ],
    chips: ['Active', 'Earnings', 'Documents'],
    actions: ['Create', 'Verify', 'Help'],
    gradientEnd: Color(0xFF31316A),
  ),
};

class Screen04WorldBody extends StatelessWidget {
  const Screen04WorldBody({
    required this.world,
    required this.choice,
    required this.area,
    required this.onPrimary,
    required this.onPlacement,
    required this.onContextAction,
    super.key,
  });

  final Screen04World world;
  final String choice;
  final String area;
  final VoidCallback onPrimary;
  final ValueChanged<String> onPlacement;
  final ValueChanged<String> onContextAction;

  @override
  Widget build(BuildContext context) {
    final spec = screen04Content[choice] ?? screen04Content['grocery']!;
    return ColoredBox(
      color: SocialV2Colors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        world.label,
                        style: const TextStyle(
                          color: SocialV2Colors.navy,
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        world.tagline,
                        style: const TextStyle(
                          color: SocialV2Colors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 34),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EB),
                    border: Border.all(color: const Color(0x33138808)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Near $area',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SocialV2Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: Key('screen04-world-${world.id}-$choice'),
                    padding: const EdgeInsets.fromLTRB(14, 3, 8, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 196),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [SocialV2Colors.navy, spec.gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spec.eyebrow.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFD7D8FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .25,
                                ),
                              ),
                              const SizedBox(height: 11),
                              Text(
                                spec.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  height: 1.04,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                spec.detail,
                                style: const TextStyle(
                                  color: Color(0xFFDCDDF5),
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 13),
                              FilledButton.icon(
                                key: const Key('screen04-primary'),
                                onPressed: onPrimary,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: SocialV2Colors.navy,
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                iconAlignment: IconAlignment.end,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  spec.primary,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                spec.section,
                                style: const TextStyle(
                                  color: SocialV2Colors.navy,
                                  fontSize: 16,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                spec.note,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: SocialV2Colors.muted,
                                  fontSize: 9.5,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = (constraints.maxWidth - 8) / 2;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: spec.cards
                                  .map(
                                    (card) => SizedBox(
                                      width: cardWidth,
                                      child: Material(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          side: const BorderSide(
                                            color: SocialV2Colors.line,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () => onPlacement(card.title),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: 126,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(11),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 3,
                                                    decoration: BoxDecoration(
                                                      color: card.tone,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            99,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 9),
                                                  Text(
                                                    card.title,
                                                    style: const TextStyle(
                                                      color:
                                                          SocialV2Colors.navy,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    card.detail,
                                                    style: const TextStyle(
                                                      color:
                                                          SocialV2Colors.muted,
                                                      fontSize: 10.5,
                                                      height: 1.3,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  const Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: CircleAvatar(
                                                      radius: 17,
                                                      backgroundColor: Color(
                                                        0xFFF0F0FC,
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        size: 16,
                                                        color: SocialV2Colors
                                                            .muted,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: spec.chips
                              .map(
                                (chip) => Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 36,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: SocialV2Colors.line,
                                    ),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    chip,
                                    style: const TextStyle(
                                      color: SocialV2Colors.navy,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  margin: const EdgeInsets.fromLTRB(0, 3, 8, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: SocialV2Colors.line),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    children: spec.actions
                        .map(
                          (action) => _ContextAction(
                            label: action,
                            onTap: () => onContextAction(action),
                          ),
                        )
                        .toList(growable: false),
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

class _ContextAction extends StatelessWidget {
  const _ContextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  IconData get icon => switch (label) {
    'Compare' || 'Share' => Icons.share_outlined,
    'Save' => Icons.bookmark_border_rounded,
    'Chat' => Icons.chat_bubble_outline_rounded,
    'Help' => Icons.help_outline_rounded,
    'Book' => Icons.calendar_month_outlined,
    'Proof' || 'Verify' || 'Accept' => Icons.check_rounded,
    'Apply' || 'Create' => Icons.work_outline_rounded,
    'Scan' => Icons.qr_code_scanner_rounded,
    'Family' => Icons.people_outline_rounded,
    _ => Icons.arrow_forward_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: SocialV2Colors.navy, size: 21),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
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
