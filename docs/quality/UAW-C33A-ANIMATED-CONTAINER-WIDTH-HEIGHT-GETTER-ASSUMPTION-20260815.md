# C33A AnimatedContainer width/height getter assumption

The first C33A analyzer rejected two assertions because Flutter's
`AnimatedContainer` widget does not expose public `width` or `height` getters.
The rendered selected-indicator dimensions must be measured through
`tester.getSize(finder)` while `widget<AnimatedContainer>` remains appropriate
only for public properties such as `duration`.

REG-2301 must be registered before correction or retry. No runtime owner
changed.
