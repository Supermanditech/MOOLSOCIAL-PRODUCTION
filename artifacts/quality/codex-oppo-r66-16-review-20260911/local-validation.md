# r66.16 local support qualification

## Final post-comment local result

Fresh enabled focused check passes4/4,exit0: r6616-support-post-comment-focused-v1.log SHA256 38785A32D23723C0525A67C10DB1618D08F460543393F1BBB52CEFB4E888E9EE. Fresh full flutter analyze --no-pub reports zero issues,exit0: r6616-support-post-comment-analysis-v1.log SHA256 8A4FA16963D55E0ADF4F614E440DA7631A791D806DC8D03E5B9F977B6800A6AC. Unchanged copy check passes,exit0: r6616-copy-corrected-v1.log SHA256 B638156BB33D2E2ABB62FC5DCEF7BB7F96C8E508E7597024C70B1AE8924D717F. Approved UI locks pass; all3 source/test owners format with0 changes; git diff --check passes. This section supersedes the post-comment pending statement below. Packaging controls and OPPO replay are still pending.

Source inputs:391; manifest SHA256 AB8FB09D37B14A667495FB8D2F4B73E321549EF7434F4F46C489AA21A67E20ED. Only chat_session.dart, chat_thread_screen.dart and global_contextual_chat_shell_test.dart differ from r66.15 manifest inputs. All raw logs and actual Flutter captures are retained externally under C:/GUARANTEED OUTCOME/MOOLSOCIAL-POST-UI-AUDIT-20260905.

## Retry diagnosis correction

Enabled attempt3 failed3 passed/1 failed: the test tapped before the lazy-list ensureVisible scroll had rendered. Raw SHA256 0B70B7624F2A1CF80636F8758917EF13AAEDDFCDD04774B80586646737BF1F26 and original compact PNG CF1CF36E3F0280C2CC8707E21CC9AD90E6F058EE78F3D3E0F86173438EBBCE59 remain. Settling that render and requiring retry.hitTestable,48px height, unchanged220px keyboard and successful single-message retry passes. The previously reported product-overlap diagnosis is withdrawn; no production layout was modified.

Unqualified working changes were preserved in r6616-support-fixture-unqualified-preservation-v1.patch, SHA256 A3D47B8C49C5E19BA1F50B1D7EEA1EC74BA0EC639023BBE0DEB27918F006A8DB; git apply --check --reverse passed against its captured working state. It is recovery evidence, not a qualified baseline.

## Focused and visual checks

From apps/mobile: flutter test --no-pub test/global_contextual_chat_shell_test.dart --plain-name r6616 --reporter expanded --concurrency=1.
- Both review flags enabled plus MOOL_CAPTURE_STORE_VIEW_V2=true, MOOL_STORE_VIEW_CAPTURE_DIR=r6616-support-review-fixture-v2 and --update-goldens:4 passed,0 failed,exit0. r6616-support-fixture-enabled-attempt5.log SHA256 FC23B3B417AE26A994026F48E34FECADBAEA94D7566D01D76C4BB6C5024C23D9.
- Neither flag (default-v2), UI-only-v1, device-only-v1: each4 passed,0 failed,exit0. Each corresponding r6616-support-fixture-<mode>.log SHA256 69AA2C4AD83FCEBE8B27104CDADBACE9F21D6720EA3557EEE1F31DB3165BE8E6. Enabled scenarios require both flags; missing-flag checks assert absent controls and unavailable arming.
- Four actual Flutter PNGs inspected in r6616-support-review-fixture-v2: error and scrolled reachable Retry at1.0/2.0. Captures are host renders, not OPPO screenshots. At compact200%, the message list requires scrolling; Retry then becomes visible and actually tappable with keyboard open.
- Full flutter analyze --no-pub: zero issues,exit0; r6616-support-full-analysis-v1.log SHA256 DF3FC37855EFE0FF30A3019132F815F8B99319B34432C8620B585935CEEB4990. Formatting of all3 source/test owners passed0 changes.

## Two current-contract cycles

Exact16/28 partitions remain in ../codex-oppo-r66-14-review-20260911/local-validation.md. Each file list was extracted from its named fenced block, checked for exact count and existence. Command: flutter test --no-pub --concurrency=1 --reporter expanded --exclude-tags protected-reference <literal partition files>. No new skip/exclusion.

| Log | Result | SHA256 |
| --- | --- | --- |
| r6616-support-connected16-cycle1.log |1458 passed,81 existing skips,0 failed,exit0|C9627378881510885D8AA07BE52AC4694460351A494D849A1F577B60AED21852|
| r6616-support-remaining28-cycle1.log |402 passed,2 existing skips,0 failed,exit0|04D688F6EEE95B688BA66DC74F47CBA97A2E339DBF1588572F740E08A53471DB|
| r6616-support-connected16-cycle2.log |1458 passed,81 existing skips,0 failed,exit0|C03572C62BC413E493996213E2E26FB38CCDB49FDB68C9D1E37C630CC4901F49|
| r6616-support-remaining28-cycle2.log |402 passed,2 existing skips,0 failed,exit0|1B6579ABD686FD28B68DF01F36C938DE8C0087FA3CFE32F453BCD5EDC1B2D09A|

Each cycle1860 passed/83 existing skips/0 failed. Overlapping focused counts are not summed as unique coverage. Two deferred Buy/Chat exploratory assertions outside this existing current-contract set remain unqualified; no Cursor integration.

## Comment-only correction and fresh checks

The unchanged copy scanner rejected a new developer comment containing a prohibited phrase. After the running frozen-source cycles finished, only 'Explicit local review fixture' became 'Explicit failure fixture'. Inverse byte hashing matches tested chat_session.dart SHA256 C23A497523F3058C9748494FA2EA5B201947140B821315DCA2A5074C1DC8C6B8, proving no executable change since those cycles. Fresh post-comment focused/analysis/copy/UI-lock results remain pending until appended; no APK qualification is asserted yet.
