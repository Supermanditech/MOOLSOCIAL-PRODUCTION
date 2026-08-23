# C29X Chat global-edge and contrast source completion

- Date: 2026-08-11
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Result: source complete; combined successor OPPO replay pending

The existing Chat owners now render a navy, white-icon Start new chat control and a compact white-backed global edge rail with Mool fixed left and the current Chat action fixed right. The rail reuses the shared compact Mool switcher, preserves the current Chat route while the switcher opens, and returns to the same thread on Back. No screen, route, service or backend owner was added.

Verification passed:

- exact Dart formatting for the two production owners and `test/chat_flow_test.dart`;
- focused analysis of all three changed owners with zero issues;
- complete `chat_flow_test.dart`: 7/7 tests passed, including 140% text scale, 360x800 fitment, 44dp controls, fixed edge positions, connected-switcher visible owner and Back recovery;
- targeted `git diff --check`: exit 0;
- exact changed-owner allowlist: three Chat files only;
- protected customer-copy owner remained at its pre-existing SHA-256 `8BB8D600D9072C69543D38B8FC20868DA7F352CFB554D5891E624BF997351CF9`.

The inherited approved-UI-lock mismatch remains a separate preserved blocker and was not modified. No build, install, OPPO mutation, deployment, provider change, message, commit, push or promotion occurred under C29X.
