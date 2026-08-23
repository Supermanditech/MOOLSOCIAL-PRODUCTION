import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/moolsocial_brand_motion.dart';

abstract final class SocialV2Colors {
  static const navy = Color(0xFF000080);
  static const royal = Color(0xFF1717A5);
  static const saffron = Color(0xFFFF9933);
  static const green = Color(0xFF138808);
  static const ink = Color(0xFF11112D);
  static const muted = Color(0xFF66677D);
  static const canvas = Color(0xFFF4F5FB);
  static const line = Color(0x1F000080);
  static const danger = Color(0xFFB42318);
  static const warning = Color(0xFF9A4F00);
}

enum SocialV2Tab { mool, shorts, videos, feed, create, chat }

class SocialV2Scaffold extends StatelessWidget {
  const SocialV2Scaffold({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.selectedTab,
    required this.onTab,
    this.searchHint,
    this.onSearch,
    this.onBack,
    this.onCreatorWorkspace,
    this.onPlans,
    this.bottomRail,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final SocialV2Tab selectedTab;
  final ValueChanged<SocialV2Tab> onTab;
  final String? searchHint;
  final VoidCallback? onSearch;
  final VoidCallback? onBack;
  final VoidCallback? onCreatorWorkspace;
  final VoidCallback? onPlans;
  final Widget? bottomRail;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: SocialV2Colors.navy,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SocialV2Colors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SocialV2Header(
                title: title,
                subtitle: subtitle,
                searchHint: searchHint,
                onSearch: onSearch,
                onBack: onBack,
                onCreatorWorkspace: onCreatorWorkspace,
                onPlans: onPlans,
              ),
              Expanded(child: body),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child:
              bottomRail ??
              SocialV2BottomRail(selected: selectedTab, onSelected: onTab),
        ),
      ),
    );
  }
}

class SocialV2Header extends StatelessWidget {
  const SocialV2Header({
    required this.title,
    required this.subtitle,
    this.searchHint,
    this.onSearch,
    this.onBack,
    this.onCreatorWorkspace,
    this.onPlans,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? searchHint;
  final VoidCallback? onSearch;
  final VoidCallback? onBack;
  final VoidCallback? onCreatorWorkspace;
  final VoidCallback? onPlans;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SocialV2Colors.navy, SocialV2Colors.royal],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                SocialV2IconButton(
                  icon: Icons.notifications_none_rounded,
                  label: 'Open notifications',
                  onPressed: () => showSocialV2Sheet(
                    context,
                    title: 'Notifications',
                    subtitle: 'Your most recent activity',
                    children: const [
                      SocialV2ListTile(
                        icon: Icons.favorite_outline_rounded,
                        title: 'Your Reel received 48 new reactions',
                        detail: 'Today · MoolSocial',
                      ),
                      SocialV2ListTile(
                        icon: Icons.campaign_outlined,
                        title: 'A campaign matches your profile',
                        detail: 'Requirements and payment appear first',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Open your MoolSocial account',
                  child: InkWell(
                    key: const Key('social-v2-account'),
                    onTap: () => showSocialV2Sheet(
                      context,
                      title: 'Your MoolSocial account',
                      subtitle: 'One identity across every Mool',
                      children: [
                        const SocialV2ListTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Your MoolSocial profile',
                          detail: 'Personal account',
                        ),
                        SocialV2ListTile(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Creator workspace',
                          detail: 'Creator Studio, campaigns and earnings',
                          onTap: onCreatorWorkspace == null
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  onCreatorWorkspace!();
                                },
                        ),
                        SocialV2ListTile(
                          icon: Icons.wallet_outlined,
                          title: 'Plans & access',
                          detail:
                              'Personal, professional and organisation tools',
                          onTap: onPlans == null
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  onPlans!();
                                },
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white10,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (onBack != null) ...[
                  SocialV2IconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Back',
                    onPressed: onBack!,
                  ),
                  const SizedBox(width: 9),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE7E7FF),
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (searchHint != null) ...[
              const SizedBox(height: 10),
              Semantics(
                button: true,
                label: searchHint,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    key: const Key('social-v2-search'),
                    onTap: onSearch,
                    borderRadius: BorderRadius.circular(17),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 50),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: SocialV2Colors.navy,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                searchHint!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SocialV2Colors.muted,
                                  fontSize: 13,
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
            ],
          ],
        ),
      ),
    );
  }
}

class SocialV2Wordmark extends StatelessWidget {
  const SocialV2Wordmark({this.compact = false, this.onPressed, super.key});

  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return MoolSocialBrandMotion(
      width: compact ? 104 : 124,
      height: compact ? 44 : 48,
      fontSize: compact ? 12 : 14,
      onDarkBackground: true,
      onPressed: onPressed,
    );
  }
}

class SocialV2IdentityLine extends StatelessWidget {
  const SocialV2IdentityLine({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        width: compact ? 70 : 92,
        height: compact ? 3 : 4,
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 45,
              child: ColoredBox(color: SocialV2Colors.saffron),
            ),
            Expanded(flex: 14, child: ColoredBox(color: Colors.white)),
            Expanded(flex: 41, child: ColoredBox(color: SocialV2Colors.green)),
          ],
        ),
      ),
    );
  }
}

class SocialV2IconButton extends StatelessWidget {
  const SocialV2IconButton({
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
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white10,
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      icon: Icon(icon),
    );
  }
}

class SocialV2BottomRail extends StatelessWidget {
  const SocialV2BottomRail({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final SocialV2Tab selected;
  final ValueChanged<SocialV2Tab> onSelected;

  static const _items = <(SocialV2Tab, String, IconData)>[
    (SocialV2Tab.mool, 'Mool', Icons.grid_view_rounded),
    (SocialV2Tab.shorts, 'Shorts', Icons.play_circle_outline_rounded),
    (SocialV2Tab.videos, 'Videos', Icons.ondemand_video_outlined),
    (SocialV2Tab.feed, 'Feed', Icons.home_outlined),
    (SocialV2Tab.create, 'Create', Icons.add_circle_outline_rounded),
    (SocialV2Tab.chat, 'Chat', Icons.chat_bubble_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: SocialV2Colors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x17000050),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        height: 76,
        child: Row(
          children: _items
              .map((item) {
                final active = selected == item.$1;
                return Expanded(
                  child: Semantics(
                    selected: active,
                    button: true,
                    child: InkWell(
                      key: Key('social-v2-tab-${item.$2.toLowerCase()}'),
                      onTap: () => onSelected(item.$1),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 58,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            color: active
                                ? SocialV2Colors.navy
                                : Colors.transparent,
                            boxShadow: active
                                ? const [
                                    BoxShadow(
                                      color: Color(0x33000080),
                                      blurRadius: 16,
                                      offset: Offset(0, 7),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.$3,
                                size: 21,
                                color: active
                                    ? Colors.white
                                    : SocialV2Colors.muted,
                              ),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.$2,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : SocialV2Colors.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class SocialV2Card extends StatelessWidget {
  const SocialV2Card({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x24000050),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: SocialV2Colors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

class SocialV2Hero extends StatelessWidget {
  const SocialV2Hero({
    required this.eyebrow,
    required this.title,
    required this.detail,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 138),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: const DecorationImage(
          image: AssetImage('assets/prototype/social-market-grocery.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xAA000040), BlendMode.srcOver),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xFFE8E8FF),
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SocialV2ListTile extends StatelessWidget {
  const SocialV2ListTile({
    required this.icon,
    required this.title,
    required this.detail,
    this.badge,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SocialV2Card(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [SocialV2Colors.navy, SocialV2Colors.green],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: SocialV2Colors.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: SocialV2Colors.muted,
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    constraints: const BoxConstraints(minHeight: 32),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8E8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: SocialV2Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SocialV2Colors.navy,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SocialV2Notice extends StatelessWidget {
  const SocialV2Notice({
    required this.title,
    required this.detail,
    this.warning = false,
    super.key,
  });

  final String title;
  final String detail;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return SocialV2Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: warning ? SocialV2Colors.saffron : SocialV2Colors.green,
            ),
            child: Icon(
              warning ? Icons.info_outline_rounded : Icons.check_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SocialV2Colors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: SocialV2Colors.muted,
                    fontSize: 11,
                    height: 1.3,
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

class SocialV2SectionTitle extends StatelessWidget {
  const SocialV2SectionTitle(this.title, {this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SocialV2Colors.navy,
            fontSize: 17,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 3),
          Text(
            detail!,
            style: const TextStyle(
              color: SocialV2Colors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class SocialV2PageList extends StatelessWidget {
  const SocialV2PageList({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 96),
    this.controller,
    super.key,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      primary: false,
      padding: padding,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => children[index],
    );
  }
}

Future<void> showSocialV2Sheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required List<Widget> children,
}) {
  final sheetTheme = Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      primary: SocialV2Colors.navy,
      secondary: SocialV2Colors.green,
      surfaceTint: Colors.transparent,
    ),
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Theme(
      data: sheetTheme,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: SocialV2Colors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: SocialV2Colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < children.length; index++) ...[
                      children[index],
                      if (index != children.length - 1)
                        const SizedBox(height: 9),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showSocialV2Message(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
