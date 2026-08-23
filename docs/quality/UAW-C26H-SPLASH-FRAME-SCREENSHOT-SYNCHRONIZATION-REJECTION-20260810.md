# C26H splash-frame screenshot synchronization rejection

- Observed: `17-social-root.png` retained the transient splash even though the subsequently captured `17-social-root.xml` already described the Social destination and approved native navigation shell.
- Classification: rejected as a truthful device-matrix screenshot; both files are preserved and are not relabeled or deleted.
- Root cause: screenshot and UI hierarchy were collected without a pre-capture foreground/readiness barrier, allowing a transient visual frame to be paired with a later semantic state.
- Permanent prevention: `capture-personal-c26h-stable-device-evidence.ps1` requires the production activity in foreground, two consecutive ready native UI dumps separated by 700 ms, absence of splash/loading semantics, a screenshot captured only after both passes, and a third ready dump plus foreground check afterward. Existing evidence is never overwritten.
- Retry rule: no C26H screenshot may enter the cumulative matrix unless produced by this stable capture owner and its machine-readable gate passes first.
