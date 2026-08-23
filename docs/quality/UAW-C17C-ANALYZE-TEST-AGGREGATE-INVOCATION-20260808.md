# C17C analyzer/test aggregate invocation

Date: 2026-08-08

One C17C command invoked focused `flutter analyze` and then the Social/Buy test
set in the same shell. Both printed explicit pass results, but the final shell
status belonged to the last command and therefore is not accepted as the
independent admission record required by regression memory. Each check must be
rerun separately and admitted from its own exit status before C17C completes.
