# C30O Firebase Chrome account-menu coordinate no-op rejection

Date: `2026-08-12`

State: `REJECTED_UI_INPUT_NO_ACCOUNT_OR_PROVIDER_MUTATION`

After the accessibility-click geometry rejection, the Firebase Console audit
captured a fresh screenshot of the exact existing Chrome window and attempted
one screenshot-backed coordinate click on the visible Google Account avatar.
The refreshed Firebase page showed no account menu, modal, focus change or
navigation result. The action is therefore a rejected no-op.

No account switched, no credential or MFA prompt opened, and no Firebase,
Play Console, browser-profile or repository configuration changed. The audit
must retain the truthful result: Chrome account index 0 is
`supermanditech@gmail.com` and cannot list the Dev project apps.

Permanent prevention: do not repeat account-avatar coordinate input on this
state and do not guess another signed-in account slot. Continue only through a
separately verified account/window surface or a founder-visible account-switch
checkpoint. Password and MFA interaction always remains with the founder.
