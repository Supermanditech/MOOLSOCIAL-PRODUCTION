import 'package:flutter/material.dart';

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
  final _areaController = TextEditingController();

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JourneyFrame(
      eyebrow: 'One-time setup',
      title: 'Make MoolSocial useful where you are',
      description:
          'Choose your language and how you want to set your service area. '
          'You can change both later.',
      child: AnimatedBuilder(
        animation: widget.session,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Language', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'hi', label: Text('हिन्दी')),
                ],
                selected: {widget.session.languageCode},
                onSelectionChanged: (value) {
                  widget.session.selectLanguage(value.first);
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Service area',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _AreaTile(
                key: const Key('area-current'),
                icon: Icons.my_location_rounded,
                title: 'Use current location',
                subtitle: 'Permission is requested only after this tap',
                selected: widget.session.areaChoice == AreaChoice.current,
                onTap: () => widget.session.selectArea(AreaChoice.current),
              ),
              _AreaTile(
                key: const Key('area-manual'),
                icon: Icons.location_on_outlined,
                title: 'Set manually',
                subtitle: 'Search an area, pin code or address',
                selected: widget.session.areaChoice == AreaChoice.manual,
                onTap: () => widget.session.selectArea(AreaChoice.manual),
              ),
              if (widget.session.areaChoice == AreaChoice.manual) ...[
                const SizedBox(height: 10),
                TextField(
                  key: const Key('manual-area-field'),
                  controller: _areaController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Area, pin code or address',
                    hintText: 'For example, Sardarpura, Jodhpur',
                  ),
                  onChanged: (value) {
                    widget.session.selectArea(
                      AreaChoice.manual,
                      label: value.trim(),
                    );
                  },
                ),
              ],
              _AreaTile(
                key: const Key('area-skip'),
                icon: Icons.arrow_forward_rounded,
                title: 'Skip for now',
                subtitle: 'We ask only when a service needs your area',
                selected: widget.session.areaChoice == AreaChoice.skipped,
                onTap: () => widget.session.selectArea(AreaChoice.skipped),
              ),
              if (widget.session.errorMessage case final message?) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  key: const Key('setup-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('continue-to-sign-in'),
                onPressed: widget.session.completeSetup,
                child: const Text('Continue'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Continuing saves only your selected setup. Marketing '
                'permission is requested separately.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MoolColors.muted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? const Color(0xFFEEF0FF) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? MoolColors.royal : MoolColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: MoolColors.royal),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? MoolColors.royal : MoolColors.line,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
