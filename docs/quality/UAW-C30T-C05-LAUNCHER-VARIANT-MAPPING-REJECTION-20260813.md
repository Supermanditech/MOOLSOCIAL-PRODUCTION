# C30T C05 launcher-variant mapping rejection — 2026-08-13

The stale `mool-root-selected` key was blanket-replaced with the compact launcher. That mapping is correct for Chat, but Shared screens intentionally render the standalone `mool-home-launcher`. The rerun therefore still failed every Shared case.

Prevention: map launcher keys by the actual navigation variant rendered by each owner: compact Chat to `mool-compact-launcher`, standalone Shared to `mool-home-launcher`.
