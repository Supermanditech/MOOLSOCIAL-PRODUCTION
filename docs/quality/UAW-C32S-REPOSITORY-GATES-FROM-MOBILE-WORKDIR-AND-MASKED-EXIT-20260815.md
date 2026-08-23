# C32S repository gates from mobile workdir and masked exit

Regression: `REG-20260815-2283-C32S-REPOSITORY-GATES-FROM-MOBILE-WORKDIR-AND-MASKED-EXIT`

A combined command invoked repository-relative PowerShell gates while its
working directory was `apps/mobile`. Those script paths were not found. The
following focused Flutter analyzer succeeded, causing the composite shell
result to be zero even though no gate had run.

The analyzer result remains valid for the migrated test, but no gate pass is
claimed from that command. Repository gates must be replayed from the exact
repository root in a separate command, followed by the focused Flutter retry
from `apps/mobile`.
