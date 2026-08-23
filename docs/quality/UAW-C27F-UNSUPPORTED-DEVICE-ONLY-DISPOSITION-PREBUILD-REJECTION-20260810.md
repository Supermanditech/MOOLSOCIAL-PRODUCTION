# C27F unsupported device-only disposition prebuild rejection

The first closed-authority wrapper self-test rejected before reaching APK
machine state because the C27F selection assessment used
`device_only_acceptance`. The delivery lock allowlist supports `reuse`,
`configuration`, `thin_policy_adapter`, `test_only_acceptance` and
`new_necessary_work`; it does not support that invented value.

No APK or provenance file was created. C27F device evidence work reuses the
existing workflow and is correctly classified as `reuse` plus `configuration`.
