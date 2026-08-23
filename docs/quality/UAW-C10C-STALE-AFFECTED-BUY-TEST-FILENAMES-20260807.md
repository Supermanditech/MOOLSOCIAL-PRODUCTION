# C10C stale affected Buy test filenames

An affected-suite preflight used two compacted-summary labels as exact paths: `buy_home_delivery_flow_test.dart` and `buy_theme_transition_test.dart`. Neither exact operand exists, and the preflight correctly prevented execution. Future affected operands are resolved from `rg --files` before existence validation.
