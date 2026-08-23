# C32X obscured launcher close-tap warnings

The warning-bearing R15 run completed 16 cases, but each of four launcher close
taps missed because the modal overlay covered the launcher. The overlay's
outside-dismiss layer received the pointer instead. That run is not accepted as
clean evidence.

C32X is corrected to target the explicit outside-dismiss owner at an
unobscured point. The next full run must have no hit-test warnings. Runtime
source remains unchanged.
