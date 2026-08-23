# C16 predecessor-audit route-identity capture mislabel

## Incident

During the required r60.15 OPPO predecessor matrix, the first attempted Social
capture was named `11-social-shorts` after a tap on the horizontally revealed
Social action. The destination rail snapped before the tap resolved and the app
remained on Eat / Book Table. The PNG and XML are preserved as rejected audit
evidence and are not counted as Social proof.

No app install, app data, accepted reference, production source or protected
runtime state changed.

## Root cause and prevention

The capture name was selected from the intended tap instead of the observed
destination identity. Every remaining predecessor and successor capture must
first prove the expected main family and selected sub-action from the fresh
UIAutomator semantics dump. A screenshot is admitted to the matrix only when
its exact PNG and paired XML agree on the family and selected state; a failed
navigation attempt receives a distinct rejected-evidence entry and is never
renamed or overwritten into valid proof.
