# C33G FIX4 prebuild/device-evidence circular dependency

- Regression: `REG-20260815-2455-C33G-FIX4-PREBUILD-DEVICE-EVIDENCE-CIRCULAR-DEPENDENCY`
- Finding: the initial `RequireReleaseReady` contract required future Play-installed OPPO evidence before the successor AAB and Internal Testing install could exist.
- Impact: no build occurred, but every legitimate successor would have been deadlocked before hidden inputs and AAB authority.
- Required correction: separate `prebuild` source qualification from `postinstall` device acceptance. Prebuild must retain explicit device-pending state; postinstall must bind resolved evidence to the exact newer candidate. Neither phase may waive the other.
