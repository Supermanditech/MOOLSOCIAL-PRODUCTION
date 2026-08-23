# UAW C33F protected-manifest comparison ephemeral shell variable

Date: 2026-08-15
Regression: `REG-20260815-2364-C33F-PROTECTED-MANIFEST-COMPARISON-EPHEMERAL-SHELL-VARIABLE`

After a valid read-only inventory showed the protected C30V set grew from 206 to 209 files, a follow-up comparison referenced `$relative` from the prior shell command. Each shell invocation is a fresh process, so the variable was absent and the reported comparison count was invalid. No manifest was generated and no product, release, device, provider or external state changed.

Recovery: register before retry and recompute both the current protected path set and the historical manifest path set inside one bounded command. Never carry shell variables across tool calls; pass durable paths or recompute a small read-only set in the same invocation.
