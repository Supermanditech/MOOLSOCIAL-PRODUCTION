# C24B3 Buy screen stale rail assertion rejection — 2026-08-09

The comprehensive Buy screen test run produced 56 passes and 13 failures. The visible failures all referenced navigation owners removed by the accepted C23 single-launcher shell: `buy-local-tab-*`, `mool-root-selected`, `mool-root-chat`, `buy-local-destination-tabs` and `moolsocial-global-navigation`. The large failing batch also exceeded the returned output budget.

The runtime source analyzer passed. The test migration must preserve business assertions while replacing retired-key setup with direct `BuyV2Session` state changes, and must use the current `MoolSocial` launcher/connected chooser only where navigation behavior is the subject. Current layout boundaries use `moolsocial-single-home-launcher-area`.
