# C30O Firebase Chrome accessibility-click geometry rejection

Date: `2026-08-12`

State: `REJECTED_UI_INPUT_NO_ACCOUNT_OR_PROVIDER_MUTATION`

The Firebase Console read-only audit reached the Dev project URL in the exact
existing Chrome window. Firebase showed that Chrome account index 0 was
`supermanditech@gmail.com` and lacked permission to list the project apps.

The audit then attempted to open the visibly labelled Google Account control
through its fresh accessibility index. The Windows-control bridge rejected the
input before dispatch with `coordinate input geometry is unavailable`.
No account switched, no credential or MFA surface opened, and no Firebase,
Play Console, browser-profile or repository configuration changed.

Permanent prevention: discard the failed accessibility index, reobserve the
same exact Chrome window with a screenshot, select one coordinate only from
that fresh screenshot-backed state, perform at most one account-menu open, and
refresh immediately. Stop at any password, MFA or authentication prompt and
leave it visibly to the founder. Never infer Firebase access from the gcloud
account or the separate Play Console organization session.
