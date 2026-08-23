# UAW C30V Play publish-dialog nested role locator no match — 2026-08-14

The Google Play `Publish change on Google Play?` modal opened and displayed its active `Save and publish` confirmation button. The browser-client nested confirmation action returned a locator-deadline error while Google Play transitioned back to the track, making the outcome ambiguous.

Immediate durable track readback proved the action completed: latest release `2026081347 (1.0.0-r60.47)`, `Available to internal testers`, release ID `4`, released `14 Aug 04:07`. No retry was performed. The permanent rule is that a browser error during a state-changing confirmation is outcome-unknown until exact external readback; never click again when the target state is already proved.
