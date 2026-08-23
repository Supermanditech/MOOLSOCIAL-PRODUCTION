# C30R journey gate install-only false-pass rejection

Date: 2026-08-12

The new C30R checker correctly sealed the Play-installed identity during its
`postinstall` phase, but its `journey` phase repeated only the install identity
assertions. It therefore printed a journey-phase pass even though the same
machine state explicitly recorded `rejected_before_first_frame_missing_Crashlytics_build_ID`.

No journey action or Create write occurred. The false pass was detected in the
same command and was not used as runtime authority.

Prevention: the `journey` phase must independently require a non-rejected
runtime-testing authorization state. An installed identity alone never permits
journey execution. Current C30R must reject journey phase until a separately
qualified successor resolves the startup defect.
