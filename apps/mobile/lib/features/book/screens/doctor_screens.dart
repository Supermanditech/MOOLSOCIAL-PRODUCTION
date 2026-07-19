import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../book_models.dart';
import '../book_session.dart';
import '../widgets/book_widgets.dart';

class DoctorBookingScreen extends StatelessWidget {
  const DoctorBookingScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Doctor',
        subtitle: 'Appointment, OPD, video or follow-up',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const BookSectionTitle(
              'Choose care',
              detail: 'Fee and proof shown',
            ),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: DoctorCare.values
                  .map(
                    (care) => MoolSegment(
                      key: Key('doctor-care-${care.name}'),
                      label: care.label,
                      selected: session.doctorCare == care,
                      onPressed: () => session.chooseDoctorCare(care),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle(
              'Tell us the need',
              detail: 'Short is enough',
            ),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: ['Fever', 'Dental', 'Child', 'Skin', 'Women', 'Reports']
                  .map(
                    (need) => MoolSegment(
                      key: Key('doctor-need-${need.toLowerCase()}'),
                      label: need,
                      selected: session.doctorNeed == need,
                      onPressed: () => session.chooseDoctorNeed(need),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle(
              'Best appointment',
              detail: 'Today · 6:20 PM',
            ),
            const SizedBox(height: MoolSpacing.sm),
            const BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.medical_services_outlined,
                    title: 'Dr. Kavita Sharma',
                    detail:
                        'General physician · verified registration and Sardarpura Clinic',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.currency_rupee_rounded,
                    title: '₹300 consultation fee',
                    detail:
                        'Approx. 12 minute wait · 7-day follow-up if offered',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            OutlinedButton.icon(
              key: const Key('doctor-ask-clinic'),
              onPressed: () => context.go(
                Uri(
                  path: '/app/chat/thread/clinic-care',
                  queryParameters: {'return': '/app/book/doctor'},
                ).toString(),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Ask clinic'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('book-doctor'),
          onPressed: () {
            session.clearMessages();
            context.go('/app/book/doctor/details');
          },
          child: Text('Continue with ${session.doctorCare.label}'),
        ),
      ),
    );
  }
}

class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({required this.session, super.key});

  final BookSession session;

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Patient details',
        subtitle: 'Share only what this appointment needs',
        fallbackBackRoute: '/app/book/doctor',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.sm,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.verified_rounded,
                title: 'Dr. Kavita Sharma · Today 6:20 PM',
                detail: 'Clinic · ₹300 · registration and clinic verified',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Who is the patient?'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: ['Self', 'Mother', 'Child']
                  .map(
                    (patient) => MoolSegment(
                      key: Key('patient-${patient.toLowerCase()}'),
                      label: patient,
                      selected: session.patient == patient,
                      onPressed: () => session.choosePatient(patient),
                    ),
                  )
                  .toList(),
            ),
            if (session.patient == 'Child') ...[
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('child-age'),
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Child age',
                  hintText: '1–17 years',
                ),
                onSubmitted: session.saveChildAge,
              ),
            ],
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Symptoms or reason'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: ['Fever', 'Cough', 'Pain', 'Reports', 'Follow-up']
                  .map(
                    (symptom) => MoolSegment(
                      key: Key('symptom-${symptom.toLowerCase()}'),
                      label: symptom,
                      selected: session.symptoms.contains(symptom),
                      onPressed: () => session.toggleSymptom(symptom),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Attach reports', detail: 'Optional today'),
            const SizedBox(height: MoolSpacing.sm),
            BookCard(
              onTap: session.toggleReport,
              child: BookFact(
                icon: session.reportAttached
                    ? Icons.check_circle_rounded
                    : Icons.upload_file_outlined,
                title: session.reportAttached
                    ? 'Lab report attached'
                    : 'Add lab report or photo',
                detail:
                    'Prescription is already linked. Reports stay private to this case.',
                trailing: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            SwitchListTile.adaptive(
              key: const Key('medical-consent'),
              value: session.medicalConsent,
              onChanged: session.setMedicalConsent,
              title: const Text('Share with this verified doctor'),
              subtitle: const Text(
                'Only appointment details and files you choose are shared.',
              ),
            ),
            if (session.appointment != null) ...[
              const SizedBox(height: MoolSpacing.sm),
              BookCard(
                color: const Color(0xFFEAF7E8),
                child: BookFact(
                  icon: Icons.event_available_rounded,
                  title: 'Appointment ${session.appointment!.id} confirmed',
                  detail:
                      'Today 6:20 PM · clinic chat, cancellation and follow-up remain available',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              OutlinedButton(
                key: const Key('open-doctor-invite'),
                onPressed: () => context.go('/app/book/doctor/invite'),
                child: const Text('Open follow-up invite'),
              ),
            ],
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('confirm-doctor-details'),
          onPressed: session.busy || session.appointment != null
              ? null
              : () async {
                  await session.confirmDoctorDetails();
                },
          child: Text(
            session.busy
                ? 'Confirming…'
                : session.appointment == null
                ? 'Confirm appointment'
                : 'Appointment confirmed',
          ),
        ),
      ),
    );
  }
}

class DoctorInviteScreen extends StatelessWidget {
  const DoctorInviteScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Clinic invite',
        subtitle: 'Verified follow-up for this visit',
        fallbackBackRoute: '/app/book/doctor/details',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            const BookCard(
              child: BookFact(
                icon: Icons.verified_user_rounded,
                title: 'Dr. Kavita Sharma',
                detail:
                    'Registration verified · Sardarpura Clinic · 7-day follow-up',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Invite options'),
            const SizedBox(height: MoolSpacing.sm),
            _DoctorInviteAction(
              actionKey: const Key('doctor-invite-show-patient-qr'),
              icon: Icons.qr_code_2_rounded,
              label: 'Show patient QR',
              onPressed: () => _showPatientInviteQr(context, session),
            ),
            _DoctorInviteAction(
              actionKey: const Key('doctor-invite-send-secure-link'),
              icon: Icons.link_rounded,
              label: 'Send secure link',
              onPressed: () => _showSecureInviteLink(context, session),
            ),
            _DoctorInviteAction(
              actionKey: const Key('doctor-invite-use-reception-code'),
              icon: Icons.pin_outlined,
              label: 'Use reception code',
              onPressed: () {
                session.createReceptionInviteCode();
                _showReceptionCode(context, session);
              },
            ),
            _DoctorInviteAction(
              actionKey: const Key('doctor-invite-add-qr-to-prescription'),
              icon: Icons.receipt_long_outlined,
              label: session.prescriptionInviteQrAdded
                  ? 'QR added to prescription'
                  : 'Add QR to prescription',
              onPressed: session.addInviteQrToPrescription,
            ),
            if (session.prescriptionInviteQrAdded)
              const BookCard(
                key: Key('doctor-prescription-qr-status'),
                color: Color(0xFFF0FAF3),
                child: BookFact(
                  icon: Icons.task_alt_rounded,
                  title: 'Prescription includes patient invite',
                  detail:
                      'The QR opens only this verified follow-up request and still requires patient approval.',
                ),
              ),
            const SizedBox(height: MoolSpacing.sm),
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.lock_outline_rounded,
                title: 'Patient approves on their phone',
                detail:
                    'No medical information is shared until the patient signs in and allows this clinic link.',
              ),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('preview-patient-invite'),
          onPressed: () => context.go('/app/book/doctor/join'),
          child: const Text('Preview patient invite'),
        ),
      ),
    );
  }
}

class PatientInviteJoinScreen extends StatelessWidget {
  const PatientInviteJoinScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Join follow-up',
        subtitle: 'Doctor invite · reports · reminders',
        fallbackBackRoute: '/app/book/doctor/invite',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            const BookCard(
              child: BookFact(
                icon: Icons.medical_services_outlined,
                title: 'Dr. Kavita Sharma',
                detail:
                    'Sardarpura Clinic · verified · 7-day follow-up for this visit',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Why join now?'),
            const SizedBox(height: MoolSpacing.sm),
            const BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.notifications_active_outlined,
                    title: 'Review and medicine reminders',
                    detail: 'The next action stays visible without a new form.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.upload_file_outlined,
                    title: 'Share reports safely',
                    detail: 'Only files you choose are linked to this case.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.event_repeat_outlined,
                    title: 'Rebook the same doctor',
                    detail: 'Clinic, video and paid review stay one tap away.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SwitchListTile.adaptive(
              key: const Key('clinic-invite-consent'),
              value: session.clinicInviteConsent,
              onChanged: session.setClinicInviteConsent,
              title: const Text('Allow this clinic link'),
              subtitle: const Text(
                'Only this verified clinic can see this visit and files you upload.',
              ),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('join-clinic-followup'),
          onPressed: () {
            if (session.joinClinicInvite()) {
              context.go('/app/book/doctor/followup');
            }
          },
          child: const Text('Sign in & link visit'),
        ),
      ),
    );
  }
}

class PatientFollowUpScreen extends StatelessWidget {
  const PatientFollowUpScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Follow-up',
        subtitle: 'Your reports, reminders and clinic access',
        activeDock: 'activity',
        fallbackBackRoute: '/app/book/home',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.event_available_rounded,
                title: 'Review due tomorrow',
                detail: 'Dr. Kavita Sharma · Sardarpura Clinic · visit linked',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Next action'),
            const SizedBox(height: MoolSpacing.sm),
            FilledButton.icon(
              key: const Key('followup-upload-report'),
              onPressed: session.uploadFollowUpReport,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                session.followUpReportUploaded
                    ? 'Report uploaded'
                    : 'Upload report',
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton.icon(
              key: const Key('followup-reminder'),
              onPressed: session.toggleMedicineReminder,
              icon: const Icon(Icons.alarm_rounded),
              label: Text(
                session.medicineReminder
                    ? 'Medicine reminder on'
                    : 'Set medicine reminder',
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton.icon(
              key: const Key('followup-book-slot'),
              onPressed: () => _showFollowUpSlots(context, session),
              icon: const Icon(Icons.video_call_outlined),
              label: Text(session.followUpSlot ?? 'Book review slot'),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Sharing control'),
            const SizedBox(height: MoolSpacing.sm),
            SwitchListTile.adaptive(
              key: const Key('followup-sharing'),
              value: session.clinicSharing,
              onChanged: session.toggleClinicSharing,
              title: const Text('Share this case with the clinic'),
              subtitle: const Text(
                'Pause anytime without deleting your private records.',
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const BookCard(
              child: BookFact(
                icon: Icons.folder_copy_outlined,
                title: 'Private health record',
                detail:
                    'Prescription saved · selected reports linked · clinic access limited to this case',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorInviteAction extends StatelessWidget {
  const _DoctorInviteAction({
    required this.actionKey,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key actionKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
      child: OutlinedButton.icon(
        key: actionKey,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

Future<void> _showPatientInviteQr(BuildContext context, BookSession session) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        0,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        key: const Key('doctor-patient-qr-sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Patient follow-up QR',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: MoolSpacing.md),
          Semantics(
            label: 'Scannable patient follow-up QR',
            child: Icon(Icons.qr_code_2_rounded, size: 176),
          ),
          const Text(
            'Expires in 10 minutes · Patient approval required',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MoolSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('doctor-patient-qr-done'),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showSecureInviteLink(BuildContext context, BookSession session) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        0,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        key: const Key('doctor-secure-link-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Secure patient invite',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'The link opens this follow-up request. The patient must sign in '
            'and approve clinic access.',
          ),
          const SizedBox(height: MoolSpacing.md),
          SelectableText(
            session.secureClinicInviteLink,
            key: const Key('doctor-secure-link-value'),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.icon(
            key: const Key('doctor-secure-link-copy'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: session.secureClinicInviteLink),
              );
              Navigator.of(sheetContext).pop();
              session.showNotice('Secure patient invite link copied.');
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy secure link'),
          ),
          TextButton(
            key: const Key('doctor-secure-link-cancel'),
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showReceptionCode(BuildContext context, BookSession session) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        0,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        key: const Key('doctor-reception-code-sheet'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Reception invite code',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: MoolSpacing.md),
          SelectableText(
            session.receptionInviteCode ?? '',
            key: const Key('doctor-reception-code-value'),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
          const Text(
            'One use · Expires in 10 minutes · No medical record is shared',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MoolSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('doctor-reception-code-done'),
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showFollowUpSlots(BuildContext context, BookSession session) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        0,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        key: const Key('followup-slot-sheet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose review slot',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: MoolSpacing.sm),
          for (final slot in const [
            ('video-today', 'Video · Today 6:20 PM'),
            ('clinic-tomorrow', 'Clinic · Tomorrow 10:30 AM'),
            ('video-tomorrow', 'Video · Tomorrow 5:40 PM'),
          ])
            ListTile(
              key: Key('followup-slot-${slot.$1}'),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                slot.$2.startsWith('Video')
                    ? Icons.video_call_outlined
                    : Icons.local_hospital_outlined,
              ),
              title: Text(slot.$2),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () {
                session.chooseFollowUpSlot(slot.$2);
                Navigator.of(sheetContext).pop();
              },
            ),
          TextButton(
            key: const Key('followup-slot-cancel'),
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}
