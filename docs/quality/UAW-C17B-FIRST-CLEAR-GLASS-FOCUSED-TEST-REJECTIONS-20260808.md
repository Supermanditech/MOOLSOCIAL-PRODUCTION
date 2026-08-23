# C17B first clear-glass focused-test rejections

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SHARED-CLEAR-GLASS-ACTION-CONTROL-FIX2-C17B`

## Truthful rejected run

The first focused run was:

```text
flutter test test/core/design/mool_clear_glass_local_navigation_c17b_test.dart
```

It failed before C17B qualification and authorized no family rollout, build or
device mutation.

## Findings registered before retry

1. The individual glass border was placed in `AnimatedContainer.decoration`.
   Flutter included that decoration padding in child layout, leaving the keyed
   `InkWell` only 46 logical pixels high even though the outside control was 48.
   The same deflation reduced the content box enough to produce one- and
   two-pixel large-text vertical overflows. The border must paint as a
   foreground decoration so it does not consume the hit/content box.
2. The new test expected a 316px four-action cluster at a 320px viewport. The
   authoritative token function preserves two 4px side insets, so the correct
   bounded cluster is 312px. Tests must derive the value from the shared token
   function instead of duplicating an incorrect number.
3. The press-state assertion sampled immediately after pointer-down. Flutter's
   `InkWell` highlight observes its finite press recognition delay, so the
   target `AnimatedScale.scale` was still `1.0` at that instant. The focused
   test must advance the recognizer interval before asserting the `.985`
   pressed target; it must still release and prove exactly one callback.

The complete rejected output remains in the task terminal history. A successor
retry is permitted only after these entries are permanent in the regression
registry and memory.

## Rejected combined patch attempt

The first combined correction patch was rejected atomically because its
pre-format test context did not match the formatter's current multiline output.
No source or test hunk from that attempt was admitted. The retry must inspect
and use exact current bounded context rather than assume formatting shape.

## Static-gate invocation rejection

The first static-gate invocation used `scripts/...` while the shell working
directory was `apps/mobile`. PowerShell could not resolve the script. The later
Flutter analyzer passed and left the combined shell with exit code zero, so
that combined result is analysis-only and is not static-gate evidence. The
gate must be run separately from the repository root so its own exit status is
authoritative.
