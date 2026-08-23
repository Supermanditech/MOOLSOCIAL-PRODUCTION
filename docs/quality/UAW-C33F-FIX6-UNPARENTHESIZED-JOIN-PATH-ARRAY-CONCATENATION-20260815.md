# UAW-C33F FIX6 unparenthesized Join-Path array concatenation

Date: 2026-08-15

## Preserved mistake

The first FIX6 parser/test command placed comma-separated `Join-Path` invocations directly inside an array expression without pre-resolving or parenthesizing each command result. PowerShell parsed them as one invocation and produced a single invalid concatenated path. The parser could not read either target, and no dedicated test or release gate executed.

## Prevention

Register before retry. Resolve each test path into its own scalar variable before creating an array, then verify each with `Test-Path -PathType Leaf` before parser invocation. Do not embed command invocations as ambiguous comma-separated array elements in qualification commands.
