# C26C MaterialApp baseline ModalBarrier test false failure

## Observation

The widget tree contained one framework `ModalBarrier` after the switcher opened even though the C26C source owner creates no barrier or dialog.

## Cause

The MaterialApp Navigator baseline was not measured before the interaction.

## Permanent prevention

- Compare the framework barrier count before and after opening.
- Keep the owner-slice machine gate forbidding `ModalBarrier`, `showGeneralDialog` and `barrierColor`.
- Use content-rect stability to prove the embedded overlay does not reflow the destination.

## Resolution evidence

The C26C widget assertion is migrated to baseline equality before retry.
