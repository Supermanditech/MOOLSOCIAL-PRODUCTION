# C25H Care Medicine cross-family rail contrast device-gate rejection

Date: 2026-08-09

Ticket: `UAW-PERSONAL-MVP-DOMAIN-NAVIGATION-OPPO-QUALIFICATION-FIX8-C25H`

Candidate: `1.0.0-r60.24` / `2026080924` / `4B261C09AA771CDEBFCEA201A1D198EA01B6E46522826C4202A9D83150DE3BF5`

Device: OPPO CPH2375, serial `2b3e0f71`

## Observed device defect

The Care family correctly keeps the `Doctor`, `Medicine` and `Salon` local actions when `Medicine` opens its reused Buy commerce destination. The rail presentation does not keep the same Care-family surface treatment:

- Doctor and Salon show the compact rail on a light neutral surface.
- Medicine inherits a dark cyan-to-navy commerce surface behind the same Care controls.
- The navy Previous and Next arrows lose contrast against that inherited surface.
- The navy MoolSocial focal control loses boundary contrast against the same surface.
- The result is not globally uniform and makes persistent navigation materially harder to discover on the Medicine destination.

Evidence:

- `artifacts/quality/uaw-personal-mvp-domain-navigation-oppo-qualification-fix8-c25h-r60-24-20260809-01/33-care-doctor-selected.png`
- `artifacts/quality/uaw-personal-mvp-domain-navigation-oppo-qualification-fix8-c25h-r60-24-20260809-01/34-care-medicine-selected.png`
- `artifacts/quality/uaw-personal-mvp-domain-navigation-oppo-qualification-fix8-c25h-r60-24-20260809-01/35-care-salon-selected.png`
- Matching UI hierarchies with the same numeric prefixes.

## Gate disposition

C25H is device-gate rejected. The installed checksum-proven r60.24 candidate is preserved for founder review. The screenshot matrix stops after Social, Shop, Food, Travel and Care; Work is intentionally not counted. No retry, second build, second install, uninstall, data clear or downgrade is authorized.

A successor must make rail surface and navigation-control contrast depend on the projected family shell, not the reused destination's business owner, and must prove Doctor, Medicine and Salon side by side on the OPPO before qualification.
