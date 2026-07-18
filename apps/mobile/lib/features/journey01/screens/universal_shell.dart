import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_theme.dart';

class UniversalShell extends StatelessWidget {
  const UniversalShell({required this.section, super.key});

  final String section;

  static const _sections = ['social', 'buy', 'mool', 'work', 'chat'];

  @override
  Widget build(BuildContext context) {
    final selected = _sections.indexOf(section).clamp(0, _sections.length - 1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: switch (section) {
            'mool' => const _MoolRoot(key: ValueKey('mool')),
            'social' => const _SocialHome(key: ValueKey('social')),
            _ => _ProductPlaceholder(key: ValueKey(section), section: section),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('universal-navigation'),
        height: 76,
        selectedIndex: selected,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8EAFF),
        onDestinationSelected: (index) {
          context.go('/app/${_sections[index]}');
        },
        destinations: const [
          NavigationDestination(
            key: Key('nav-social'),
            icon: Icon(Icons.play_circle_outline_rounded),
            selectedIcon: Icon(Icons.play_circle_fill_rounded),
            label: 'Social',
          ),
          NavigationDestination(
            key: Key('nav-buy'),
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: 'Buy',
          ),
          NavigationDestination(
            key: Key('nav-mool'),
            icon: _MoolIcon(selected: false),
            selectedIcon: _MoolIcon(selected: true),
            label: 'Mool',
          ),
          NavigationDestination(
            key: Key('nav-work'),
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Work',
          ),
          NavigationDestination(
            key: Key('nav-chat'),
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

class _MoolIcon extends StatelessWidget {
  const _MoolIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MoolColors.royal, MoolColors.navy],
        ),
        shape: BoxShape.circle,
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x552636D9),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: const Text(
        'M',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SocialHome extends StatelessWidget {
  const _SocialHome({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'MoolSocial',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            const CircleAvatar(
              backgroundColor: Color(0xFFE8EAFF),
              child: Text('J', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Search people, products or local posts',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onTap: () {},
        ),
        const SizedBox(height: 20),
        Container(
          height: 360,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF161D7D), Color(0xFF313FD3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Pill(label: 'NEAR YOU'),
              Spacer(),
              Text(
                'Your people, local life and useful actions—together.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'The social feed is the default home. Buying or work appears '
                'only when you choose it.',
                style: TextStyle(color: Color(0xFFDDE0FF), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _MoolRoot extends StatelessWidget {
  const _MoolRoot({super.key});

  static const _actions = [
    ('Buy', 'Products delivered home', Icons.shopping_bag_rounded, 'buy'),
    ('Eat', 'Food, tables and tiffin', Icons.restaurant_rounded, 'eat'),
    ('Ride', 'Book a safe local ride', Icons.directions_car_rounded, 'ride'),
    ('Book', 'Services and appointments', Icons.calendar_month_rounded, 'book'),
    (
      'Pay',
      'Pay and view receipts',
      Icons.account_balance_wallet_rounded,
      'pay',
    ),
    ('Work', 'Funded verified opportunities', Icons.work_rounded, 'work'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      children: [
        Text('Mool', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'What do you want to get done?',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: MoolColors.muted),
        ),
        const SizedBox(height: 22),
        TextField(
          key: const Key('mool-search'),
          decoration: const InputDecoration(
            hintText: 'Search an action or say what you need',
            prefixIcon: Icon(Icons.auto_awesome_rounded),
          ),
          onSubmitted: (_) {},
        ),
        const SizedBox(height: 26),
        ..._actions.map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                key: Key('mool-action-${action.$4}'),
                borderRadius: BorderRadius.circular(22),
                onTap: () => context.go('/app/${action.$4}'),
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF1FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(action.$3, color: MoolColors.royal),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              action.$1,
                              style: const TextStyle(
                                color: MoolColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              action.$2,
                              style: const TextStyle(
                                color: MoolColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({required this.section, super.key});

  final String section;

  @override
  Widget build(BuildContext context) {
    final title = section[0].toUpperCase() + section.substring(1);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_rounded, size: 52, color: MoolColors.royal),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text(
              '$title is connected to the universal shell. Its complete '
              'end-to-end journey is delivered as a separate production slice.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: MoolColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
