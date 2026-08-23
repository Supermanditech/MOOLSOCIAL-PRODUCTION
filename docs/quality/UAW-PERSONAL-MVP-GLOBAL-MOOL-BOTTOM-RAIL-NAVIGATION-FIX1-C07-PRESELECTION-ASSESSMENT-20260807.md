# C07 durable Mool home and persistent root-rail preselection assessment

Date: 7 August 2026
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C07-DURABLE-MOOL-HOME-PERSISTENT-ROOT-RAIL`
Classification: `mvp_required`

## Founder-visible failure

The r60.7 OPPO frame opened `/app/mool` as a full-screen navigation-only
question-and-grid launcher. The page said `Where do you want to go?`, rendered
six route-choice tiles, and labelled its otherwise empty middle dock `Jump
anywhere in one tap`. Although it was a route instead of a modal, its only
customer purpose was still to open another route. It therefore repeated the
founder-rejected popup/menu behavior in another visual shape.

This is a production regression and not a review preference. The current APK
remains `installed_device_rejected_preserved` and cannot be promoted or called
production-qualified.

## Screenbook reconciliation

Read-only Screen 04 is approved historical input, but its exact Mool interaction
is superseded by the founder's newer MVP direction. It defines a hidden
`role="menu"` Mool action ribbon, toggles `mool-mode`, and defaults the app to
Social. Those mechanics are precisely the behavior now rejected on OPPO.

C07 reuses only the still-valid Screen 04 principles: one focused product or
service world at a time, stable Mool and Chat edge controls, contextual
sub-actions, finite motion and direct action wording. It does not reuse the
popup/ribbon, Social default or obsolete Pay action.

## Smallest production-grade successor

- Keep the existing `/app/mool` route and `PersonalMoolRootV2` owner.
- Replace the navigation-only question/grid body with a durable Mool home that
  truthfully shows the selected area and, when opened from another owner, a
  one-tap `Continue <origin>` card using the existing exact Back callback.
- Put Social, Buy, Eat, Ride, Book and Work permanently in the Mool home's
  middle bottom rail between selected Mool and Chat. The six actions use a
  readable horizontal rail with minimum tap geometry; they are not a popup,
  modal, palette, overlay or temporary mode.
- Preserve the existing action routes, product/service owners, sessions,
  contextual sub-action rails, stack pushes, exact Back behavior and global
  Chat return contract.
- Keep the selected Mool control idempotent. Retapping it never resets the
  route, opens an overlay or changes lifecycle state.
- Use only existing local session truth. No catalogue, provider result,
  recommendation, availability, order, trip, booking, work or chat data is
  fabricated.

## Machine-blocking acceptance

The versioned C07 scenario ledger is required by the static navigation checker.
The checker rejects the known launcher copy/keys and requires the durable-home
and persistent-root-rail markers. Production-router tests must prove visible
owners and retained state. The OPPO phase must retain screenshot plus hierarchy
evidence for every applicable ledger row before the machine state can move from
`unimplemented_or_unverified_blocking_successor`.

## Scope and prohibitions

No new named route, backend, provider, store, persistent domain state or
protected Social/Buy content owner. Screenbook remains read-only. No credentials,
live provider activity, payment/funds, Production write, commit, push, deploy,
promotion, OPPO uninstall, data clear or downgrade. No build or install is
authorized merely by this implementation ticket; any new APK requires a fresh
candidate identity and the complete machine/build/device gates.
