# Prototype-to-production traceability

The production app does not recreate 167 independent HTML pages. It consolidates
the prototype evidence into stable routes and state machines.

| Prototype | Production owner | Current status |
| --- | --- | --- |
| Screen 00 Install App | Play Store listing and release pipeline | contract |
| Screen 01 Splash / First Open | `/boot` | local UI and routing implemented |
| Screen 02 Language / Location | `/setup` | local UI and validation implemented |
| Screen 03 Login / Handoff | `/sign-in`, `/verify` | deterministic adapter implemented; live Firebase pending |
| Screen 04 Universal Focus Shell | `/app/social`, `/app/mool`, universal nav | local shell implemented |

The exact source requirements remain in:

`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\00-install-app.html`
through
`C:\GUARANTEED OUTCOME\supermandi-uiux-screenbook\screens\04-universal-focus-shell.html`.

Any production change to this journey must update its journey contract and replay
tests in the same commit.
