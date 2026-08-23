# UAW-R31 Medical Store/Pharmacy routing reference hold

Date: 6 August 2026
Ticket: `UAW-R31-MEDICAL-STORE-PHARMACY-ROUTING-REFERENCE`
State: `REFERENCE_HELD_NOT_SELECTED_NOT_EXECUTING`

## Disposition

R31 remains `mvp_required`, but it is not executable without the
`pharmacy_licence_and_buy_capability_owner`. Only a currently licensed exact
Medicine fulfilment workspace may expose medicine offer, pharmacist review,
acceptance, packing and regulated handover. It must not imply clinical advice
or automatic substitution.

Repository inventory confirms `SUP-002` and `DISC-005` are blocked and the Buy
portfolio's licensed-pharmacy assignment remains held by regulatory evidence.
Existing UI copy that says “licensed pharmacy” is not a current licence,
service-area, pack, pharmacist or medicine-handling capability projection.

No source, HTML reference, licence/medicine data, backend, build, APK or device
action was performed for R31. The ticket will be reassessed after the pharmacy
licence, regulatory evidence and exact Buy capability owners are active.

Next child by manifest order for reference disposition:
`UAW-R32-SALON-PARLOUR-ROUTING-REFERENCE`.
