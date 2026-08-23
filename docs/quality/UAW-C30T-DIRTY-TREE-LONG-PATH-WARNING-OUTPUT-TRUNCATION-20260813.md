# C30T dirty-tree long-path warning output truncation

## Incident

The line-delimited dirty-tree retry correctly treated porcelain lines as
records, but Git emitted a very large set of warnings for retained evidence
paths longer than the default Windows handling limit. Those warnings shared the
tool output and caused truncation. All displayed counts and the hash from that
run were rejected.

## Impact

The diagnostic was read-only and changed no repository, Git reference, build,
external service or device state. It did not prove complete dirty ownership.

## Prevention

The next reconciliation must use per-command `core.longpaths=true`, capture
stderr independently in an exact verified workspace-local temporary file, and
admit counts/hash only if Git exits zero and stderr is empty. The tool output
must contain only the compact validated summary. The temporary diagnostic file
is removed only after its absolute path is verified to remain under the
repository `tmp` directory.
