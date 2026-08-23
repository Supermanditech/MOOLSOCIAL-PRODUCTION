# C30T release registrant cardinality drift finding

Date: 2026-08-13

## Gate rejection

The C30T reconcile gate passed with build/upload/install counts `0/0/0`. The following static release-readiness gate rejected the current generated Android registrant because it contains 16 plugin registrations while the qualified C30T release contract requires exactly 15.

## Required classification before correction

The exact sixteenth owner must be compared with the prior qualified allow-list and classified as legitimate production ownership, dependency drift, or test/tooling contamination. No dependency or generated file is changed until that classification is evidence-backed.

No APK/AAB was built, no authority was consumed, and no upload/install/deployment/external action occurred.

## Classification and correction

The sixteenth registration was `IntegrationTestPlugin`; Flutter metadata marks it `dev_dependency: true`. All exact 15 release-native owners remained present. Reproduction proved that Flutter test tooling can leave 16 registrations, while a final release config-only step returns to 15; later Flutter tooling can contaminate it again.

The qualifier and single-AAB wrapper now both run `scripts/restore-release-generated-plugin-registrant-c30t.ps1` immediately after their final release config-only step. The helper validates metadata ownership, removes only an exact dev integration block if present, and proves all 15 allowed release classes. Recovery passed with APK absent and the sealed r60.44 AAB unchanged; wrapper and static readiness gates now pass.
