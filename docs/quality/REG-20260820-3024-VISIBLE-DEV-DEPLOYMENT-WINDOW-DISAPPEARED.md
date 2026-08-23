# REG-20260820-3024 visible Dev deployment window disappeared

## Incident

After action-time founder confirmation, the primary opened a visible PowerShell
window running the exact Firebase deployment command for
`moolSocialPublicAuth`. Before any public client IDs were entered, the founder
reported that no PowerShell window remained open.

## Impact

- No runtime parameter or secret value was entered through that window.
- The local process/session outcome is ambiguous and no deployment success is
  claimed.
- No build, Play, OPPO, email, SMS or private login occurred.
- An authoritative Dev function-existence readback is required before retry.

## Root cause

The external visible process was launched without a durable session handle or
an explicit founder prompt acknowledgement, so its disappearance could not be
distinguished from closure, immediate command completion or launch failure.

## Prevention

Do not retry the deployment until an authoritative sanitized function readback
proves whether it exists. Then open one visible `-NoExit` PowerShell, first
confirm the prompt is visible, and only afterward have the founder type the
exact deployment command and respond to the four public runtime parameters.
