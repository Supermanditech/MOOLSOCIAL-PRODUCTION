import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/design/mool_theme.dart';
import '../journey_session.dart';
import '../widgets/journey_frame.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({required this.session, super.key});

  final JourneySession session;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _areaController = TextEditingController(text: 'Jodhpur');
  bool _languageApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_languageApplied) return;
    _languageApplied = true;
    final deviceLanguage = Localizations.localeOf(context).languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.session.selectLanguage(deviceLanguage == 'hi' ? 'hi' : 'en');
      }
    });
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    await widget.session.useCurrentLocation();
    if (!mounted) return;
    if (widget.session.areaChoice == AreaChoice.current) {
      await widget.session.completeSetup();
    }
  }

  Future<void> _skipNow() async {
    widget.session.selectArea(AreaChoice.skipped);
    await widget.session.completeSetup();
  }

  @override
  Widget build(BuildContext context) {
    return JourneyFrame(
      eyebrow: '',
      title: 'Almost ready',
      description:
          'Choose your language and how MoolSocial should set your area.',
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          final manual = widget.session.areaChoice == AreaChoice.manual;
          final errorMessage = widget.session.errorMessage;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MoolColors.navy,
              border: Border.all(color: MoolColors.navy),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageChoice(
                        key: const Key('language-en'),
                        label: 'English',
                        selected: widget.session.languageCode == 'en',
                        onTap: widget.session.busy
                            ? null
                            : () => widget.session.selectLanguage('en'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LanguageChoice(
                        key: const Key('language-hi'),
                        label: 'हिन्दी',
                        selected: widget.session.languageCode == 'hi',
                        onTap: widget.session.busy
                            ? null
                            : () => widget.session.selectLanguage('hi'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set your area',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Use your current place if you are there now, or set your '
                  'home/default area if you are travelling.',
                  style: TextStyle(
                    color: Color(0xFFE4E4FF),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                if (!manual) ...[
                  _LocationChoice(
                    key: const Key('area-current'),
                    type: _LocationArtworkType.current,
                    title: 'Use current location',
                    subtitle: 'Best when you are at the place now',
                    onTap: widget.session.busy ? null : _useCurrentLocation,
                  ),
                  const SizedBox(height: 8),
                  _LocationChoice(
                    key: const Key('area-manual'),
                    type: _LocationArtworkType.manual,
                    title: 'Set manually',
                    subtitle: 'Search area, pin code, address or choose on map',
                    onTap: widget.session.busy
                        ? null
                        : () {
                            widget.session.selectArea(
                              AreaChoice.manual,
                              label: _areaController.text.trim(),
                            );
                          },
                  ),
                  const SizedBox(height: 8),
                  _LocationChoice(
                    key: const Key('area-skip'),
                    type: _LocationArtworkType.skip,
                    title: 'Skip now',
                    subtitle: 'Continue to login and set area after signup',
                    onTap: widget.session.busy ? null : _skipNow,
                  ),
                ] else
                  _ManualArea(
                    controller: _areaController,
                    errorMessage: widget.session.errorMessage,
                    busy: widget.session.busy,
                    onBack: () => widget.session.selectArea(AreaChoice.skipped),
                    onChanged: (value) => widget.session.selectArea(
                      AreaChoice.manual,
                      label: value.trim(),
                    ),
                    onContinue: widget.session.completeSetup,
                  ),
                if (!manual && errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage,
                    key: const Key('setup-error'),
                    style: const TextStyle(
                      color: Color(0xFFFFD2D2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Use $label',
      child: Material(
        color: selected ? Colors.white : Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? MoolColors.navy : Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationChoice extends StatelessWidget {
  const _LocationChoice({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final _LocationArtworkType type;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _LocationArtwork(type: type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _LocationArtworkType { current, manual, skip }

class _LocationArtwork extends StatelessWidget {
  const _LocationArtwork({required this.type});

  final _LocationArtworkType type;

  @override
  Widget build(BuildContext context) {
    final asset = switch (type) {
      _LocationArtworkType.current => 'assets/prototype/location-current.svg',
      _LocationArtworkType.manual => 'assets/prototype/location-manual.svg',
      _LocationArtworkType.skip => 'assets/prototype/location-skip.svg',
    };
    return SizedBox(
      width: 42,
      height: 42,
      child: SvgPicture.asset(asset, width: 40, height: 40),
    );
  }
}

class _ManualArea extends StatelessWidget {
  const _ManualArea({
    required this.controller,
    required this.errorMessage,
    required this.busy,
    required this.onBack,
    required this.onChanged,
    required this.onContinue,
  });

  final TextEditingController controller;
  final String? errorMessage;
  final bool busy;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final Future<bool> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .10),
        border: Border.all(color: Colors.white70),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Search area, pin code or address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            key: const Key('manual-area-field'),
            controller: controller,
            enabled: !busy,
            textInputAction: TextInputAction.done,
            onChanged: onChanged,
            decoration: const InputDecoration(
              hintText: 'Search area, pin code or address',
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final area in const ['Jodhpur', 'Sardarpura', 'Ratanada'])
                ActionChip(
                  key: Key('area-suggestion-${area.toLowerCase()}'),
                  label: Text(area),
                  onPressed: busy
                      ? null
                      : () {
                          controller
                            ..text = area
                            ..selection = TextSelection.collapsed(
                              offset: area.length,
                            );
                          onChanged(area);
                        },
                ),
            ],
          ),
          if (errorMessage case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              key: const Key('setup-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const Key('continue-to-sign-in'),
                  onPressed: busy ? null : onContinue,
                  child: Text(
                    busy ? 'Saving…' : 'Use ${controller.text.trim()}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
