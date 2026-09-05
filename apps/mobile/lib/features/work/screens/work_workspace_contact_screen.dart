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
  late final TextEditingController _name;
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
    _name = TextEditingController(text: widget.session.authorizedPersonName);
  }

  @override
  void didUpdateWidget(covariant WorkWorkspaceContactScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.session.hydrateAccountSnapshot(widget.accountSnapshot);
    for (final field in [
      (_primaryMobile, widget.session.primaryMobile),
      (_email, widget.session.contactEmail),
      (_alternate, widget.session.alternateMobile),
      (_name, widget.session.authorizedPersonName),
    ]) {
      if (field.$1.text.isEmpty && field.$2.isNotEmpty) {
        field.$1.value = TextEditingValue(
          text: field.$2,
          selection: TextSelection.collapsed(offset: field.$2.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _primaryMobile.dispose();
    _email.dispose();
    _alternate.dispose();
    _name.dispose();
    _primaryOtp.dispose();
    _emailOtp.dispose();
    _alternateOtp.dispose();
    super.dispose();
  }

  void _continue() {
    widget.session.savePersonName(_name.text);
    if (_name.text.trim().length < 2) {
      widget.session.errorMessage = 'Enter your full name to continue.';
      setState(() {});
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.session.continueToProof()) {
      if (GoRouterState.of(context).uri.queryParameters['return'] == 'review' &&
          context.canPop()) {
        context.pop();
      } else {
        context.push('/app/work/workspace/proof');
      }
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
                  label: 'Continue',
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
                          'Saved details appear below. Confirm new or changed contacts.',
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    TextField(
                      key: const Key('work-person-name'),
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      onChanged: session.savePersonName,
                      decoration: const InputDecoration(
                        labelText: 'Your full name',
                        helperText: 'The person setting up this Workspace',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    _ContactVerificationCard(
                      keyName: 'work-primary-contact',
                      title: 'Contact number',
                      detail: 'A number you can answer for customer calls',
                      requiredContact: true,
                      controller: _primaryMobile,
                      otpController: _primaryOtp,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      confirmed: session.primaryMobileVerified,
                      otpSent: session.primaryMobileOtpSent,
                      busy: session.busy,
                      onEdit: (value) {
                        session.editWorkspaceContact(
                          WorkContactChannel.primaryMobile,
                          value,
                        );
                        _primaryOtp.clear();
                      },
                      confirmedMessage: 'Contact confirmed',
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
                      onEdit: (value) {
                        session.editWorkspaceContact(
                          WorkContactChannel.email,
                          value,
                        );
                        _emailOtp.clear();
                      },
                      confirmedMessage: 'Contact confirmed',
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
                          'Optional backup if you cannot answer your usual phone',
                      requiredContact: false,
                      controller: _alternate,
                      otpController: _alternateOtp,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      confirmed: session.alternateVerified,
                      otpSent: session.alternateOtpSent,
                      busy: session.busy,
                      onEdit: (value) {
                        session.editWorkspaceContact(
                          WorkContactChannel.alternateMobile,
                          value,
                        );
                        _alternateOtp.clear();
                      },
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

class _WorkspaceAccountHero extends StatelessWidget {
  const _WorkspaceAccountHero({required this.session, required this.profile});
  final WorkSession session;
  final WorkProfileOption profile;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MoolMotion.accessible(context, MoolMotion.standard),
    builder: (context, value, child) => Opacity(opacity: value, child: child),
    child: Container(
      key: const Key('workspace-account-setup-hero'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MoolColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stay within reach',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Keep customer calls and important updates close.',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ConnectedAccountCard extends StatelessWidget {
  const _ConnectedAccountCard({required this.session});
  final WorkSession session;

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('work-connected-provider-account'),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(
          _providerIcon(session.connectedProviderLabel),
          color: MoolColors.navy,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signed in with ${session.connectedProviderLabel}',
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                session.connectedProviderAccount.isEmpty
                    ? session.accountDisplayName
                    : session.connectedProviderAccount,
                style: const TextStyle(color: MoolColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
    required this.onEdit,
    this.prefixText,
  });
  final String keyName, title, detail, confirmedMessage;
  final bool requiredContact, confirmed, otpSent, busy;
  final TextEditingController controller, otpController;
  final TextInputType keyboardType;
  final String? prefixText;
  final VoidCallback onSend, onVerify, onChange;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    key: Key(keyName),
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: Key('$keyName-field'),
          controller: controller,
          enabled: !busy,
          readOnly: confirmed,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          scrollPadding: const EdgeInsets.only(bottom: 32),
          onChanged: onEdit,
          decoration: InputDecoration(
            labelText: requiredContact ? title : '$title · optional',
            helperText: detail,
            helperMaxLines: 2,
            prefixText: prefixText,
            border: const UnderlineInputBorder(),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCACEE0)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: MoolColors.navy, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: confirmed
                ? const Icon(Icons.check_circle_outline, color: MoolColors.navy)
                : null,
          ),
        ),
        if (confirmed)
          Row(
            children: [
              Expanded(
                child: Text(
                  confirmedMessage,
                  style: const TextStyle(color: MoolColors.navy, fontSize: 12),
                ),
              ),
              TextButton(
                key: Key('$keyName-change'),
                onPressed: busy ? null : onChange,
                child: const Text('Change'),
              ),
            ],
          )
        else if (!otpSent)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: Key('$keyName-send-otp'),
              onPressed: busy || (!requiredContact && controller.text.isEmpty)
                  ? null
                  : onSend,
              child: Text(busy ? 'Please wait…' : 'Send code'),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          TextField(
            key: Key('$keyName-otp'),
            controller: otpController,
            enabled: !busy,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            decoration: InputDecoration(
              labelText: '$title code',
              helperText: 'Sent to ${controller.text}',
              helperMaxLines: 2,
              counterText: '',
              border: const UnderlineInputBorder(),
            ),
            onSubmitted: (_) {
              if (!busy) onVerify();
            },
          ),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: busy ? null : onSend,
                child: const Text('Resend code'),
              ),
              FilledButton(
                key: Key('$keyName-confirm-otp'),
                onPressed: busy ? null : onVerify,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: MoolColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Confirm', maxLines: 1, softWrap: false),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _ContactReadinessSummary extends StatelessWidget {
  const _ContactReadinessSummary({required this.session});

  final WorkSession session;

  @override
  Widget build(BuildContext context) {
    final missing = <String>[
      if (!session.primaryMobileVerified) 'phone number',
      if (!session.contactEmailVerified) 'email',
      if (session.alternateMobile.isNotEmpty && !session.alternateVerified)
        'alternate contact',
    ];
    final ready = missing.isEmpty;
    return Padding(
      key: const Key('work-contact-readiness'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ready ? Icons.task_alt_rounded : Icons.info_outline,
            color: MoolColors.navy,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ready
                  ? 'Contact details ready'
                  : 'Confirm your ${missing.join(' and ')} to continue.',
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 12,
                height: 1.4,
              ),
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
