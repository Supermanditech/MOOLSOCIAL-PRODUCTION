# REG2644 — C33V source-gate process count repeated REG2582 self-matching

Date: 2026-08-16 IST

After the C33V source gate exceeded the command yield window, the first
sanitized `Win32_Process` count searched for the target script text but did not
exclude the querying PowerShell process. Its own command line contained the
same target text, so the returned count could include itself and cannot prove
that the source gate was still active.

This repeats the self-matching diagnostic class prohibited by REG2582. The
query did not inspect or expose terminal input, secrets or environment values,
and it caused no build, Play or OPPO action. The candidate remained pre-seal.

Exclude the current PowerShell PID inside the same query, output only the
sanitized count, wait for zero, and rerun the source gate with a retained
unified-exec session and completion marker. Count no source-gate pass from the
lost session.
