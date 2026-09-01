import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../widgets/work_widgets.dart';
import '../work_models.dart';
import '../work_session.dart';

class WorkWorkspaceContactScreen extends StatefulWidget {
  const WorkWorkspaceContactScreen({
    required this.session,
    required this.accountSnapshot,
    super.key,
  });

  final WorkSession session;
  final WorkAccountSnapshot accountSnapshot;

  @override
  State<WorkWorkspaceContactScreen> createState() =>
      _WorkWorkspaceContactScreenState();
}

class _WorkWorkspaceContactScreenState
    extends State<WorkWorkspaceContactScreen> {
  late final TextEditingController _primaryMobile;
  late final TextEditingController _email;
  late final TextEditingController _alternate;
  final TextEditingController _primaryOtp = TextEditingController();
  final TextEditingController _emailOtp = TextEditingController();
  final TextEditingController _alternateOtp = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.session.hydrateAccountSnapshot(widget.accountSnapshot);
    _primaryMobile = TextEditingController(text: widget.session.primaryMobile);
    _email = TextEditingController(text: widget.session.contactEmail);
    _alternate = TextEditingController(text: widget.session.alternateMobile);
  }

  @override
  void dispose() {
    _primaryMobile.dispose();
    _email.dispose();
    _alternate.dispose();
    _primaryOtp.dispose();
    _emailOtp.dispose();
    _alternateOtp.dispose();
    super.dispose();
  }

  void _continue() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.session.continueToProof()) {
      context.push('/app/work/workspace/proof');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final profile = session.selectedProfile;
        return WorkPageScaffold(
          session: session,
          title: 'Set up your Workspace',
          subtitle: profile?.label ?? 'Choose a Workspace first',
          fallbackBackRoute: '/app/work/workspace/requirements',
          activeLocalAction: 'workspace',
          showHeaderChat: false,
          showTrailingAction: false,
          bottomAction: profile == null
              ? null
              : WorkPrimaryButton(
                  keyName: 'work-contact-continue',
                  label: session.workspaceContactsReady
                      ? 'Continue to Workspace details'
                      : 'Confirm main contact and email',
                  onPressed: _continue,
                ),
          body: ListView(
            key: const Key('work-contact-screen'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.sm,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: profile == null
                ? [
                    WorkEmptyState(
                      title: 'No Workspace selected',
                      detail:
                          'Choose the Workspace that best matches what you do.',
                      actionLabel: 'Browse Workspaces',
                      onAction: () {
                        session.changeFamily();
                        context.go('/app/work/my-work');
                      },
                    ),
                  ]
                : [
                    _WorkspaceAccountHero(session: session, profile: profile),
                    const SizedBox(height: MoolSpacing.md),
                    if (session.connectedProviderLabel.isNotEmpty) ...[
                      _ConnectedAccountCard(session: session),
                      const SizedBox(height: MoolSpacing.md),
                    ],
                    const WorkSectionTitle(
                      title: 'How MoolSocial can reach you',
                      detail:
                          'Information already available is filled in. Confirm only what is missing or changed.',
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _ContactVerificationCard(
                      keyName: 'work-primary-contact',
                      title: 'Main contact number',
                      detail:
                          'Required for orders, payments and urgent support',
                      requiredContact: true,
                      controller: _primaryMobile,
                      otpController: _primaryOtp,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      confirmed: session.primaryMobileVerified,
                      otpSent: session.primaryMobileOtpSent,
                      busy: session.busy,
                      confirmedMessage:
                          'Confirmed from your MoolSocial account',
                      onSend: () async {
                        await session.sendPrimaryMobileOtp(_primaryMobile.text);
                      },
                      onVerify: () async {
                        await session.verifyPrimaryMobileOtp(_primaryOtp.text);
                      },
                      onChange: () {
                        session.changePrimaryMobile();
                        _primaryMobile.clear();
                        _primaryOtp.clear();
                      },
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _ContactVerificationCard(
                      keyName: 'work-contact-email',
                      title: 'Email address',
                      detail:
                          'Required for review updates, invoices and recovery',
                      requiredContact: true,
                      controller: _email,
                      otpController: _emailOtp,
                      keyboardType: TextInputType.emailAddress,
                      confirmed: session.contactEmailVerified,
                      otpSent: session.contactEmailOtpSent,
                      busy: session.busy,
                      confirmedMessage:
                          'Confirmed from your MoolSocial account',
                      onSend: () async {
                        await session.sendContactEmailOtp(_email.text);
                      },
                      onVerify: () async {
                        await session.verifyContactEmailOtp(_emailOtp.text);
                      },
                      onChange: () {
                        session.changeContactEmail();
                        _email.clear();
                        _emailOtp.clear();
                      },
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    _ContactVerificationCard(
                      keyName: 'work-alternate-contact',
                      title: 'Alternate contact number',
                      detail:
                          'Optional backup for work alerts when the main number is unavailable',
                      requiredContact: false,
                      controller: _alternate,
                      otpController: _alternateOtp,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      confirmed: session.alternateVerified,
                      otpSent: session.alternateOtpSent,
                      busy: session.busy,
                      confirmedMessage: 'Alternate contact confirmed by OTP',
                      onSend: () async {
                        if (_alternate.text.trim().isEmpty) {
                          session.removeAlternateMobile();
                          return;
                        }
                        await session.sendAlternateOtp(_alternate.text);
                      },
                      onVerify: () async {
                        await session.verifyAlternateOtp(_alternateOtp.text);
                      },
                      onChange: () {
                        session.removeAlternateMobile();
                        _alternate.clear();
                        _alternateOtp.clear();
                      },
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _ContactReadinessSummary(session: session),
                  ],
          ),
        );
      },
    );
  }
}

class _WorkspaceAccountHero extends StatefulWidget {
  const _WorkspaceAccountHero({required this.session, required this.profile});

  final WorkSession session;
  final WorkProfileOption profile;

  @override
  State<_WorkspaceAccountHero> createState() => _WorkspaceAccountHeroState();
}

class _WorkspaceAccountHeroState extends State<_WorkspaceAccountHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    _controller.repeat(reverse: true, count: 4).whenComplete(() {
      if (mounted) _controller.value = 1;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    final session = widget.session;
    return AnimatedBuilder(
      animation: motion,
      builder: (context, child) => Container(
        key: const Key('workspace-account-setup-hero'),
        padding: const EdgeInsets.all(MoolSpacing.sm),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MoolColors.navy,
              Color.lerp(
                const Color(0xFF3535B8),
                const Color(0xFF006D5B),
                motion.value,
              )!,
            ],
          ),
          borderRadius: BorderRadius.circular(MoolRadii.floating),
          boxShadow: [
            BoxShadow(
              color: MoolColors.orange.withValues(
                alpha: .12 + (.08 * motion.value),
              ),
              blurRadius: 14 + (6 * motion.value),
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: MoolColors.orange,
                foregroundColor: MoolColors.navy,
                child: Icon(Icons.person_pin_circle_outlined),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MAKE YOUR WORKSPACE REACHABLE',
                      style: TextStyle(
                        color: Color(0xFFFFD6AD),
                        fontSize: 9.5,
                        letterSpacing: .45,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      widget.profile.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'One clear account for customer contact, payments and important Workspace updates.',
            style: TextStyle(
              color: Color(0xFFE8E8FF),
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _HeroFact(
                  label: 'ACCOUNT',
                  value: session.connectedProviderLabel.isEmpty
                      ? 'MoolSocial'
                      : session.connectedProviderLabel,
                  ready: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HeroFact(
                  label: 'MAIN CONTACT',
                  value: session.primaryMobileVerified ? 'Ready' : 'Needed',
                  ready: session.primaryMobileVerified,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _HeroFact(
                  label: 'EMAIL',
                  value: session.contactEmailVerified ? 'Ready' : 'Needed',
                  ready: session.contactEmailVerified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({
    required this.label,
    required this.value,
    required this.ready,
  });

  final String label;
  final String value;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(MoolRadii.control),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDADAF7),
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ready ? Colors.white : const Color(0xFFFFD6AD),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedAccountCard extends StatelessWidget {
  const _ConnectedAccountCard({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: 'work-connected-provider-account',
      color: const Color(0xFFEDEEFF),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: MoolColors.navy,
            foregroundColor: Colors.white,
            child: Icon(_providerIcon(session.connectedProviderLabel)),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.connectedProviderLabel} account',
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  session.connectedProviderAccount.isEmpty
                      ? session.accountDisplayName
                      : session.connectedProviderAccount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Only this signed-in account is shown for this setup.',
                  style: TextStyle(color: MoolColors.muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
          const WorkPill(label: 'Connected', color: MoolColors.success),
        ],
      ),
    );
  }
}

class _ContactVerificationCard extends StatelessWidget {
  const _ContactVerificationCard({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.requiredContact,
    required this.controller,
    required this.otpController,
    required this.keyboardType,
    required this.confirmed,
    required this.otpSent,
    required this.busy,
    required this.confirmedMessage,
    required this.onSend,
    required this.onVerify,
    required this.onChange,
    this.prefixText,
  });

  final String keyName;
  final String title;
  final String detail;
  final bool requiredContact;
  final TextEditingController controller;
  final TextEditingController otpController;
  final TextInputType keyboardType;
  final bool confirmed;
  final bool otpSent;
  final bool busy;
  final String confirmedMessage;
  final VoidCallback onSend;
  final VoidCallback onVerify;
  final VoidCallback onChange;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: keyName,
      color: confirmed ? const Color(0xFFEAF7E8) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              WorkPill(
                label: requiredContact ? 'Required' : 'Optional',
                color: requiredContact ? MoolColors.navy : MoolColors.orange,
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          TextField(
            key: Key('$keyName-field'),
            controller: controller,
            enabled: !confirmed && !busy,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.done,
            scrollPadding: const EdgeInsets.only(bottom: 150),
            decoration: InputDecoration(
              prefixText: prefixText,
              suffixIcon: confirmed
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: MoolColors.success,
                    )
                  : null,
            ),
          ),
          if (confirmed) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: MoolColors.success,
                  size: 17,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    confirmedMessage,
                    style: const TextStyle(
                      color: MoolColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  key: Key('$keyName-change'),
                  onPressed: busy ? null : onChange,
                  child: const Text('Use another'),
                ),
              ],
            ),
          ] else if (!otpSent)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: Key('$keyName-send-otp'),
                onPressed: busy ? null : onSend,
                icon: const Icon(Icons.sms_outlined, size: 18),
                label: const Text('Send OTP'),
              ),
            )
          else ...[
            const SizedBox(height: MoolSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('$keyName-otp'),
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '6-digit OTP',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                SizedBox(
                  width: 104,
                  child: FilledButton(
                    key: Key('$keyName-confirm-otp'),
                    onPressed: busy ? null : onVerify,
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactReadinessSummary extends StatelessWidget {
  const _ContactReadinessSummary({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final missing = <String>[
      if (!session.primaryMobileVerified) 'main contact',
      if (!session.contactEmailVerified) 'email',
      if (session.alternateMobile.isNotEmpty && !session.alternateVerified)
        'alternate contact',
    ];
    final ready = missing.isEmpty;
    return WorkCard(
      keyName: 'work-contact-readiness',
      color: ready ? const Color(0xFFEAF7E8) : const Color(0xFFFFF4E5),
      child: Row(
        children: [
          Icon(
            ready ? Icons.task_alt_rounded : Icons.pending_actions_outlined,
            color: ready ? MoolColors.success : MoolColors.orange,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'Contact details ready' : 'Complete required contact',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ready
                      ? 'You can continue to Workspace details.'
                      : 'Still needed: ${missing.join(' and ')}.',
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
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

IconData _providerIcon(String label) => switch (label.toLowerCase()) {
  'youtube' => Icons.play_circle_outline_rounded,
  'x' => Icons.alternate_email_rounded,
  'facebook' => Icons.facebook_rounded,
  'google' => Icons.g_mobiledata_rounded,
  _ => Icons.account_circle_outlined,
};
