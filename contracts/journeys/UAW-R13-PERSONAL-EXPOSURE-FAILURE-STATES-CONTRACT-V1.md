# UAW-R13 Personal exposure failure states contract V1

| State | Last safe context | Permitted recovery | Forbidden claim |
| --- | --- | --- | --- |
| Loading | retained | no synthetic action | current/active result |
| Held | retained | return to safe choices | approval or activation |
| Disabled | retained | return to safe choices | capability/eligibility |
| Stale | retained | request a fresh projection | cached value is current |
| Offline | retained | retry after reconnection | empty/denied/global outage |
| Denied | retained | return to safe choices | another workspace existence |

One shared native panel owns the exact copy and callback semantics. It is a
reference/native presentation owner, not a live source of state. R01 remains a
static fixture and cannot trigger a live state, grant a capability or prove a
server decision. Runtime integration requires a separately gated authoritative
`launch_policy_owner`.
