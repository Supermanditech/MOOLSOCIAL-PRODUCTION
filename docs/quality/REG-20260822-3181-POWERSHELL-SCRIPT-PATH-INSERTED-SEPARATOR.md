# REG3181 - PowerShell script path inserted separator

## Classification

Registered founder-facing PowerShell command-path rejection with zero Flutter,
APK, install or device action and both one-action authorities unconsumed.

## Evidence

The supplied retry command used
`./scripts/build-buy-device-review/.ps1` semantics instead of the actual file
`./scripts/build-buy-device-review.ps1`. PowerShell correctly rejected the
nonexistent literal path before invoking any script. Independent readback
proved the correct file exists, the malformed path does not, and build/install
counters remain zero.

## Permanent prevention

Before giving a founder any copy/paste-ready PowerShell command:

1. Resolve every repository script path from the live filesystem.
2. Require `Test-Path -LiteralPath <path> -PathType Leaf` to return true.
3. Preserve the exact filename and extension; never insert a separator before
   `.ps1`.
4. Present ordinary Windows PowerShell syntax using one backslash per path
   separator.
5. If PowerShell rejects command discovery, register the failure and reverify
   the literal path before one classified retry.
