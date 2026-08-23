# C29O API-owner absence-search terminal-exit rejection

Date: 2026-08-11
Ticket context: `UAW-PERSONAL-MVP-SOCIAL-END-TO-END-ACTION-TRUTH-AND-ACCESSIBILITY-C29O`

## Rejected attempt

A bounded audit command printed the exact file line count and then ended with an
`rg` symbol search. The file contained none of the queried symbols, so the
expected empty search returned exit 1 and made the compound command report
failure. The output is not used to infer the owner's contents.

No product, provider, device, protected release or scope state changed.

## Permanent prevention

- A line count and an absence-capable search are separate commands.
- If an empty result is meaningful, the command explicitly maps `rg` exit 1 to
  an admitted empty result and rejects exit codes greater than 1.
- Small owners are read literally rather than approximated from symbol names.
