# REG3003 — MVP module readiness interpolated-colon parser failure

Date: 20 August 2026 (IST)
State: registered before subagent retry

## Incident

After its mandatory gates passed, `/root/mvp_module_readiness` composed a
read-only module-root summary command whose throw string contained
`"rg failed for $root: $LASTEXITCODE"`. PowerShell rejected the command before
execution because a colon immediately followed `$root`. Exit was `1`; the
command body did not run and the assigned readiness document remained the
primary-created pending stub.

## Root cause

The diagnostic repeated the permanent PowerShell interpolated-variable colon
class instead of using the format operator or an explicitly delimited variable.

## Prevention

The retry uses the format operator for every path/status error message, runs
only after refreshed memory and coordination gates, and remains read-only
except for the single assigned output owner. The rejected command is never
reused.

## Retained evidence

- `docs/quality/MVP-MODULE-INTEGRATION-READINESS-20260820.md`
- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- subagent stop report in the `20-08-2026` production-auth task
