# C16A local-action semantics missing tap owner rejection

## Incident

The second C16A focused run compiled and passed compact layout, large text,
target size, reduced motion and token tests. Its one-tap semantics assertion
failed: an available local action reported `enabled=true` but exposed no
assistive tap action.

## Root cause and prevention

The shared cell used `excludeSemantics=true`, so the descendant InkWell did not
contribute its tap action, while the outer Semantics node omitted `onTap`.
Available actions now assign the same callback to both the physical InkWell and
the outer semantics owner; selected actions keep both callbacks null. Focused
coverage proves available actions expose exactly one semantic tap outcome and
selected actions remain inert.
