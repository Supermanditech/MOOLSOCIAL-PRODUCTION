# C29N protected Create test dock-during-composition mismatch

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1236-C29N-PROTECTED-CREATE-TEST-DOCK-DURING-COMPOSITION-MISMATCH`

The finite publish CTA removed the prior layout exception. The targeted Screen
04 journey then reached an inherited step that tapped Mool while the composer
was active. C29N intentionally hides Mool, Chat and local navigation during
composition to preserve full-height keyboard space, so the old finder was
correctly absent.

The protected journey now proves dock absence during composition, closes through
the explicit composer action, verifies edge restoration, and only then exercises
the connected chooser and Back lifecycle.
