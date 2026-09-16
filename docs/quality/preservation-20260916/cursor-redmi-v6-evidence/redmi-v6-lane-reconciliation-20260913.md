# Independent Redmi lane reconciliation

The previous coordination probe used primary /root with cursor_ui. Source inspection establishes that cursor_ui requires role subagent and task prefix /root/cursor_. Therefore that particular rejection was an invocation mismatch, not proof that the gate had checked a correctly registered Redmi task. It remains a failed probe, not a pass.

Separate, directly inspected registration gap: the preserved V6 configuration contains zero continuation bindings for redmi-v6-audit-20260913. Its default cursor_ui lane starts from the governance tag and forbids scripts/ owners. The new task instead starts from V6 and has explicit founder approval for scripts/check-approved-ui-locks.ps1. A dedicated, exact continuation/owner admission is therefore needed to reconcile the actual authorized task with machine-enforced identity. No old task should be reused to impersonate an admission.

The scope is still one independent Redmi build and audit. No policy, lane defaults or checker predicates were changed during this reconciliation. The approved 26-line UI-lock change remains the only modified repository file, uncommitted. Its full actual check and ten isolated cases passed as already recorded.

The resolution message expressly limits existing approval to the single UI-lock proposal. Additional registration and protected-Buy path admission are not silently authorized. The independent task's exact task identity, V6 continuation base, existing single-file exception and build/evidence owner paths must be represented through a separately reviewed, bounded admission before commit/build; all global lane defaults must remain unchanged. The protected-Buy review root restriction is a second unchanged prerequisite. No build or device result is claimed.
