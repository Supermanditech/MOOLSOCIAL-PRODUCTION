# C29L PowerShell foreach-pipe parser rejection

Before any C29L mutation, a read-only required-reading inventory attempted to pipe directly from a `foreach` statement without wrapping the statement as an expression. PowerShell rejected the command with `An empty pipe element is not allowed`; no repository, device, cloud or runtime state changed.

The retry is constrained to collect the loop output into a candidate-specific array and pipe that array only after the loop completes. Future multi-file inventories use the same parser-safe form.
