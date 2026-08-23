# C20H SurfaceFlinger layer remote-shell quoting rejection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-GLOBAL-SUBACTION-OPPO-QUALIFICATION-FIX3-C20H`

## Rejection

The exact MoolSocial BLAST layer was inventoried, but its first latency probe
passed the layer name without remote-shell quoting. Android rejected the
parenthesized name with `syntax error: unexpected '('`; no frame evidence was
accepted.

## Prevention

SurfaceFlinger latency probes now use one remote command string with the exact
inventoried layer name enclosed in remote single quotes. The probe must produce
a refresh-period line and timestamp rows before any measured transition begins.
