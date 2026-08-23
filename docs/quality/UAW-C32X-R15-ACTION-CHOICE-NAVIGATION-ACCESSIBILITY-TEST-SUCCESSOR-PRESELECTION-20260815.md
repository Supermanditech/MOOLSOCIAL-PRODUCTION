# C32X R15 action-choice navigation accessibility test successor preselection

C32W passed fifteen R15 cases before exposing a hidden assertion for the
removed `mool-action-<family>` control in standalone `MvpActionChoiceRootV2`.
The exact current FIX2 authority uses `mool-home-launcher`, opens the connected
family menu, and requires `mool-root-selected` and `mool-root-chat` to remain
absent.

C32X permits migration of only that hidden assertion block. The explicit
outside-dismiss owner must close the connected menu without hit-test warnings,
after which Back must invoke the root callback. All action, projection, legacy
recovery and prior Home coverage remains. Runtime and every live/release
authority remain closed.
