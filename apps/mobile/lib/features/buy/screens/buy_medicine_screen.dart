import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyMedicineScreen extends StatefulWidget {
  const BuyMedicineScreen({required this.session, super.key});

  final BuySession session;

  @override
  State<BuyMedicineScreen> createState() => _BuyMedicineScreenState();
}

class _BuyMedicineScreenState extends State<BuyMedicineScreen> {
  late final TextEditingController _search = TextEditingController(
    text: widget.session.medicineQuery,
  );
  final _question = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => BuyPageScaffold(
        key: const Key('buy-medicine-screen'),
        session: widget.session,
        title: 'Medicines & pharmacy',
        subtitle: 'Licensed sellers · prescription rules shown',
        fallbackBackRoute: '/app/buy?sub=medicine',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xxl,
          ),
          children: [
            const _MedicineSafetyCard(),
            const SizedBox(height: MoolSpacing.md),
            Wrap(
              key: const Key('medicine-paths'),
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: BuyMedicinePath.values
                  .map(
                    (path) => MoolSegment(
                      key: Key('medicine-path-${path.name}'),
                      label: path.label,
                      selected: widget.session.medicinePath == path,
                      onPressed: () => widget.session.chooseMedicinePath(path),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.md),
            switch (widget.session.medicinePath) {
              BuyMedicinePath.search => _SearchMedicines(
                session: widget.session,
                controller: _search,
              ),
              BuyMedicinePath.prescription => _PrescriptionRequest(
                session: widget.session,
              ),
              BuyMedicinePath.pharmacist => _PharmacistRequest(
                session: widget.session,
                controller: _question,
              ),
            },
          ],
        ),
        bottomAction: widget.session.itemCount == 0
            ? null
            : FilledButton.icon(
                key: const Key('medicine-view-basket'),
                onPressed: () => context.go('/app/buy/basket'),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                  'Review basket · ${buyMoney(widget.session.subtotal)}',
                ),
              ),
      ),
    );
  }
}

class _MedicineSafetyCard extends StatelessWidget {
  const _MedicineSafetyCard();

  @override
  Widget build(BuildContext context) {
    return const BuySurfaceCard(
      color: Color(0xFFEAF7E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: MoolColors.success),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Text(
                  'Choose with clear pharmacy rules',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MoolSpacing.xs),
          Text(
            'Availability comes from licensed sellers. A prescription item is '
            'not charged or confirmed until a pharmacy accepts the prescription.',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchMedicines extends StatelessWidget {
  const _SearchMedicines({required this.session, required this.controller});

  final BuySession session;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final medicines = session.visibleMedicines(controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('medicine-search'),
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: session.updateMedicineQuery,
          decoration: InputDecoration(
            hintText: 'Search medicine or pharmacy',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    key: const Key('medicine-search-clear'),
                    tooltip: 'Clear search',
                    onPressed: () {
                      controller.clear();
                      session.updateMedicineQuery('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const Text(
          'Available medicines',
          style: TextStyle(
            color: MoolColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        if (medicines.isEmpty)
          BuySurfaceCard(
            key: const Key('medicine-empty'),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 42,
                  color: MoolColors.muted,
                ),
                const SizedBox(height: MoolSpacing.xs),
                const Text(
                  'No listed medicine matches this search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextButton(
                  key: const Key('medicine-empty-clear'),
                  onPressed: () {
                    controller.clear();
                    session.updateMedicineQuery('');
                  },
                  child: const Text('Clear search'),
                ),
              ],
            ),
          )
        else
          ...medicines.map(
            (medicine) => Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.sm),
              child: _MedicineCard(session: session, medicine: medicine),
            ),
          ),
      ],
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.session, required this.medicine});

  final BuySession session;
  final BuyProduct medicine;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      key: Key('medicine-${medicine.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDEEFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: MoolColors.navy,
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medicine.detail,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      medicine.seller,
                      style: const TextStyle(
                        color: MoolColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                buyMoney(medicine.price),
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Text(
            medicine.requiresPrescription
                ? 'Prescription required · no charge before acceptance'
                : 'Prescription not required for this listed item',
            style: TextStyle(
              color: medicine.requiresPrescription
                  ? const Color(0xFF9A4D00)
                  : MoolColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          FilledButton(
            key: Key('medicine-primary-${medicine.id}'),
            onPressed: () {
              if (medicine.requiresPrescription) {
                session.selectMedicine(medicine.id);
              } else {
                session.addMedicine(medicine.id);
              }
            },
            child: Text(
              medicine.requiresPrescription
                  ? 'Add prescription'
                  : 'Add to basket',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionRequest extends StatelessWidget {
  const _PrescriptionRequest({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final medicine = session.selectedMedicine;
    if (medicine == null || !medicine.requiresPrescription) {
      return BuySurfaceCard(
        key: const Key('medicine-prescription-empty'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a prescription medicine',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Search first, then add the prescription requested for that '
              'specific medicine.',
              style: TextStyle(color: MoolColors.muted, height: 1.4),
            ),
            const SizedBox(height: MoolSpacing.md),
            OutlinedButton(
              key: const Key('medicine-prescription-search'),
              onPressed: () =>
                  session.chooseMedicinePath(BuyMedicinePath.search),
              child: const Text('Search medicines'),
            ),
          ],
        ),
      );
    }

    return BuySurfaceCard(
      key: const Key('medicine-prescription-request'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            medicine.name,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${medicine.unitLabel} · ${buyMoney(medicine.price)} · ${medicine.seller}',
            style: const TextStyle(color: MoolColors.muted, fontSize: 12),
          ),
          const SizedBox(height: MoolSpacing.md),
          Container(
            padding: const EdgeInsets.all(MoolSpacing.sm),
            decoration: BoxDecoration(
              color: session.prescriptionAttached
                  ? const Color(0xFFEAF7E8)
                  : const Color(0xFFFFF3E5),
              borderRadius: BorderRadius.circular(MoolRadii.control),
            ),
            child: Row(
              children: [
                Icon(
                  session.prescriptionAttached
                      ? Icons.check_circle_rounded
                      : Icons.description_outlined,
                  color: session.prescriptionAttached
                      ? MoolColors.success
                      : MoolColors.orange,
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: Text(
                    session.prescriptionAttached
                        ? 'Prescription added'
                        : 'Prescription required',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          OutlinedButton.icon(
            key: const Key('medicine-prescription-attach'),
            onPressed: session.medicineRequestId == null
                ? session.attachPrescription
                : null,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
              session.prescriptionAttached
                  ? 'Replace prescription'
                  : 'Choose prescription',
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          FilledButton(
            key: const Key('medicine-prescription-submit'),
            onPressed: session.medicineBusy || session.medicineRequestId != null
                ? null
                : session.submitPrescription,
            child: session.medicineBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    session.medicineRequestId == null
                        ? 'Send to licensed pharmacy'
                        : 'Request sent',
                  ),
          ),
          if (session.medicineRequestId case final requestId?) ...[
            const SizedBox(height: MoolSpacing.md),
            Semantics(
              liveRegion: true,
              child: Container(
                key: const Key('medicine-prescription-result'),
                padding: const EdgeInsets.all(MoolSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7E8),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Text(
                  'Request $requestId sent. The pharmacy will show acceptance, '
                  'availability and final amount before payment.',
                  style: const TextStyle(
                    color: Color(0xFF155B17),
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PharmacistRequest extends StatelessWidget {
  const _PharmacistRequest({required this.session, required this.controller});

  final BuySession session;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      key: const Key('medicine-pharmacist-request'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ask a licensed pharmacist',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Ask about availability, prescription requirements or an existing '
            'pharmacy request. This does not replace medical care.',
            style: TextStyle(color: MoolColors.muted, height: 1.4),
          ),
          const SizedBox(height: MoolSpacing.md),
          TextField(
            key: const Key('medicine-pharmacist-question'),
            controller: controller,
            minLines: 3,
            maxLines: 5,
            enabled: session.pharmacistRequestId == null,
            decoration: const InputDecoration(
              hintText: 'What do you need help with?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          FilledButton(
            key: const Key('medicine-pharmacist-submit'),
            onPressed:
                session.medicineBusy || session.pharmacistRequestId != null
                ? null
                : () => session.requestPharmacist(controller.text),
            child: session.medicineBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    session.pharmacistRequestId == null
                        ? 'Send question'
                        : 'Question sent',
                  ),
          ),
          if (session.pharmacistRequestId case final requestId?) ...[
            const SizedBox(height: MoolSpacing.md),
            Semantics(
              liveRegion: true,
              child: Container(
                key: const Key('medicine-pharmacist-result'),
                padding: const EdgeInsets.all(MoolSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7E8),
                  borderRadius: BorderRadius.circular(MoolRadii.control),
                ),
                child: Text(
                  'Request $requestId is open. Reply and status will appear in '
                  'Chat. No payment was taken.',
                  style: const TextStyle(
                    color: Color(0xFF155B17),
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
