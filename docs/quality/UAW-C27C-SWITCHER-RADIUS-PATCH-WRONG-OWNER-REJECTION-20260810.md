# C27C switcher-radius patch wrong-owner rejection

## Observation

The C27C gate exposed that the radius-token patch changed the earlier private
direct-action button's identical `BorderRadius.circular(16)` expression while
the actual `MoolConnectedActionNavigator` panel still hardcoded 16.

## Cause

The patch used a generic method-body context instead of anchoring the exact
switcher class, so the first matching radius owner was changed.

## Permanent prevention

When repeated literals exist in one large Dart file, inspect and anchor the
exact class declaration in the patch hunk. The focused source gate must prove
the token appears inside the bounded panel owner, not merely anywhere in the
file.

## Resolution evidence

The gate rejected before qualification. The exact two owners were inspected and
this mistake registered before the direct-action radius is restored and the
panel radius is tokenized.
