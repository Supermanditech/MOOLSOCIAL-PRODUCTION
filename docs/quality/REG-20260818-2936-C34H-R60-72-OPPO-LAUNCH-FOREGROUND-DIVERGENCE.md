# REG2936 — C34H r60.72 OPPO launch foreground divergence

## Observed event

With exactly one connected OPPO CPH2375, the existing Play-installed MoolSocial r60.72 launch returned `Status: ok` for `com.moolsocial.app/.MainActivity`. The immediately guarded read-only activity check then found MoolSocial was not the resumed foreground activity. The command stopped before inspecting the other surface.

## Impact

- No account chooser, provider, private identifier, UI hierarchy, screenshot, email, phone, OTP, credential, or other private surface was read or captured.
- No provider tap, install, uninstall, sideload, data clear, downgrade, build, upload, or external write occurred.
- The existing r60.72 predecessor remains rejected and is not represented as current r60.76 evidence.

## Root cause boundary

The launched activity did not remain foreground; the exact destination (launcher, lock screen, crash, or another system state) was intentionally not inspected before registration.

## Mandatory prevention

1. After registration, query only the sanitized foreground package name and current MoolSocial process/fatal/ANR counts allowed by the actor policy.
2. If the foreground is a system/private/account surface, stop without UI inspection and hand control to the founder.
3. If MoolSocial exited/crashed, retain only sanitized process/fatal evidence and do not retry as proof of authentication.
4. Never capture or inspect non-MoolSocial UI content.
