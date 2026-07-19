import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../book_session.dart';
import '../widgets/book_widgets.dart';

class BookHomeScreen extends StatelessWidget {
  const BookHomeScreen({required this.session, this.initialIntent, super.key});

  final BookSession session;
  final String? initialIntent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Book',
        subtitle: 'Price, time and proof before confirm',
        showBack: false,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            TextField(
              key: const Key('book-search'),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search doctor, salon or task',
              ),
              onSubmitted: (value) {
                final query = value.trim().toLowerCase();
                if (query.isEmpty) {
                  session.showError('Enter what you want to book.');
                } else if (query.contains('doctor') ||
                    query.contains('clinic') ||
                    query.contains('hospital')) {
                  context.go('/app/book/doctor');
                } else if (query.contains('salon') ||
                    query.contains('hair') ||
                    query.contains('makeup')) {
                  context.go('/app/book/salon');
                } else {
                  context.go('/app/book/task');
                }
              },
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle(
              'What do you need?',
              detail: 'One decision at a time',
            ),
            const SizedBox(height: MoolSpacing.sm),
            _EntryCard(
              key: const Key('book-home-task'),
              icon: Icons.task_alt_rounded,
              title: 'Get It Done',
              description:
                  'Send a verified helper for a pickup, document or market task.',
              facts: const ['From ₹99', 'Payment protected', 'Proof required'],
              emphasized: initialIntent == 'get-done',
              onTap: () => context.go('/app/book/task'),
            ),
            const SizedBox(height: MoolSpacing.sm),
            _EntryCard(
              key: const Key('book-home-doctor'),
              icon: Icons.medical_services_outlined,
              title: 'Doctor',
              description:
                  'Book a clinic, hospital OPD, video or follow-up appointment.',
              facts: const ['₹300 fee', 'Verified registration', '12 min wait'],
              emphasized: initialIntent == 'doctor',
              onTap: () => context.go('/app/book/doctor'),
            ),
            const SizedBox(height: MoolSpacing.sm),
            _EntryCard(
              key: const Key('book-home-salon'),
              icon: Icons.content_cut_rounded,
              title: 'Salon',
              description:
                  'Choose a salon visit, home visit, makeup or package.',
              facts: const ['From ₹199', 'Slot today', 'Free cancel window'],
              emphasized: initialIntent == 'salon',
              onTap: () => context.go('/app/book/salon'),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.verified_user_outlined,
                title: 'Commit only after review',
                detail:
                    'Provider proof, exact price, timing, cancellation and support remain visible before every confirmation.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.facts,
    required this.onTap,
    this.emphasized = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> facts;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return BookCard(
      onTap: onTap,
      color: emphasized ? const Color(0xFFF1F0FF) : Colors.white,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: MoolColors.navy,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                Wrap(
                  spacing: MoolSpacing.xs,
                  runSpacing: 3,
                  children: facts
                      .map(
                        (fact) => Text(
                          fact,
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: MoolColors.navy),
        ],
      ),
    );
  }
}
