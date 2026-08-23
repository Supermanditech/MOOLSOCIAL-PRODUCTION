# UAW C33J IntrinsicHeight and shrink-wrap GridView conflict

- Regression: `REG-20260815-2491-C33J-INTRINSIC-HEIGHT-SHRINKWRAP-GRIDVIEW-CONFLICT`
- Failure: the first focused native v5 widget test reached Flutter layout and rejected `IntrinsicHeight` above the chooser's shrink-wrapped provider `GridView`.
- Impact: all focused tests failed at layout; no provider, email, build, Play or device action occurred.
- Repair rule: remove the intrinsic-dimension request, keep the body scrollable, and prove the chooser plus 320x568 at 140 percent text before broader qualification.
