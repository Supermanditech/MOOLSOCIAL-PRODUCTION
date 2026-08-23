# UAW C30V visible founder launcher path-argument quoting failure — 2026-08-14

## Incident

The first `Start-Process` attempt supplied the spaced C30V launcher path as an unquoted `ArgumentList` element. The child PowerShell process exited immediately before presenting or consuming the founder prompts.

Exact machine-state readback proved `source_qualified_founder_secret_prompt_required`, build authority `available_once`, build/wrapper/upload/install counts `0/0/0/0`, both founder-qualified runtime flags false, both agent-read flags false, and no artifact owner. No AAB, upload, install, deployment, or OPPO mutation occurred.

## Prevention

Launch the exact same sealed wrapper again with an explicitly quoted `-File` argument. Never infer progress from a returned process ID; if a process exits unexpectedly, reconcile the exact machine-state owner before any retry.
