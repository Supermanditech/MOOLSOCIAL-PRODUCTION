# r66.16 bounded support review disposition

Current stage: r66.16 built, checksum-matched installed, bounded native support recovery completed. See post-install.json and device-review.md. Founder reaffirmed testing/recording only after this install: no product fixes or further APK builds until the original27 device audit is accounted for.

Original27-item inventory and12 historical OPPO findings remain in ../codex-oppo-r66-15-review-20260911/ticket-and-screen-coverage.md and device-review.md (latest native224 checkpoint controls older counts). One malformed-phone behavior was narrowly corrected and device-retested; eleven findings remain open. This candidate does not close those unrelated children or the entire27-item batch.

REG4550: add controlled review-only failed send to make the missing OPPO support retry scenario reachable. Local normal/200% keyboard tests and actual renders pass after fixing test render timing. The earlier host-overlap product diagnosis is withdrawn, not promoted to an OPPO child.
REG4549: preserve exact-application identity, unsent drafts and reply/media context while observing failure/retry/Back. Existing regression coverage passes; pending native successor replay must prove actual observations, not infer from tests.

Native update035: REG4550 now has its missing controlled frontend failure scenario on OPPO: error/retained draft, keyboard-open reachable Retry and single-message completion pass. REG4549 same-application Back/reopen preserves both an unsent draft and a failed draft; retry after reentry also passes. No real transport was exercised. Application A/B switching, support process death and physical200%/TalkBack are not newly passed.

Original27 inventory now has24 items with related native evidence, two host investigations and one founder-held product-add item. Related evidence does not imply complete parent closure. Twelve historical native findings remain: one narrowly corrected/retested, eleven open; zero additional distinct device findings in this bounded continuation. No unsupported fixture/backend case is marked device-passed. Full per-item predecessors and explicit limitations remain in the r66.15 ledger; latest r66.16 support results supersede only its missing-error-scenario status.

OPPO plan: verify exact package/APK checksum, install without clearing data; open an exact synthetic review application support thread; arm one failure with keyboard closed; enter a clearly marked QA draft; fail only through ReviewChatSendGateway; verify error and retained draft; retry once; inspect single local message, no duplicate effect; navigate Back/re-enter and compare application A/B drafts; register genuine device defects. Do not send to real support or WhatsApp.

Backend authority/transport, unsupported receipt/offer/history event simulations, deferred Cursor procurement/Buy checks, physical200%/TalkBack and founder-held product-add redesign remain separate limitations. Report incomplete cases honestly; do not label all27 device-qualified from this bounded replay.
