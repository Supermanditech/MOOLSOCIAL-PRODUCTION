# REG-20260822-3206 — apkanalyzer dex packages unsupported help option

## Incident

A read-only `apkanalyzer dex packages --help` diagnostic printed the option
table but then rejected `help` as an unrecognized option.

## Impact

- Additional APK or AAB builds: `0`
- Sealed artifacts: `0`
- OPPO actions: `0`
- Private/provider actions: `0`

## Root cause

The diagnostic assumed GNU-style subcommand help support instead of using the
analyzer's established syntax or its already displayed supported options.

## Permanent prevention

Do not invoke `apkanalyzer dex packages` with `--help`. Use only its displayed
supported options, such as `--defined-only` and mapping inputs, and register
any nonzero diagnostic before a corrected invocation.
