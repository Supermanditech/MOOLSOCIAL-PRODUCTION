# C14 44px strip top border deflated actions to 43px

Date: 2026-08-08

Regression:
`REG-20260808-281-C14-44PX-STRIP-TOP-BORDER-DEFLATED-ACTIONS-TO-43PX`

## Failure

The first C14 geometry run measured the next keyed action at 43 logical pixels
for Social, Buy, Eat, Ride, Book and Work. The complete strip was 44px, but its
one-pixel decorated top border reduced the content layout available to the
interactive child.

## Root cause and prevention

This recurred from the registered nominal-envelope class: total height does not
prove child height. The layout-consuming border is removed. The two-pixel
family connector remains a `Positioned` paint layer over the full 44px child,
so it identifies family ownership without deflating hit geometry. Tests measure
the actual keyed controls in all six normal and compact large-text owners.
