# REG2784 — C34L completed-agent notice thread limit

Date: 17 August 2026
State: registered nonessential coordination failure; no repository impact

## Mistake

After PRE-AAB-3-FIX1 dual-host qualification completed, the agent attempted to
send a duplicate stability notice to the already completed transition agent.
The collaboration service returned `agent thread limit reached`. The state
owner had already received the required notice, and no repository mutation,
test result or external state was affected.

## Prevention

Check live agent status before sending coordination messages. Do not notify a
completed agent unless a new turn is genuinely required; route final stable
hashes through the primary and active dependent owner only.
