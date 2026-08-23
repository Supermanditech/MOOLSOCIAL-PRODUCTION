# C16 IME-dismissal dual-signal transient rejection

## Incident

After the Social Create predecessor capture, Back changed OPPO input-method
state to `mShowRequested=false` and `mInputShown=false`, while the same fresh
sample still reported `mIsInputViewShown=true`. The device gate rejected the
attempt before any Buy navigation or capture occurred.

No install, app data, accepted reference, production source or protected
runtime state changed.

## Root cause and prevention

The input-method service can expose a short dismissal interval in which the
requested/shown and input-view visibility signals have not converged. C16 does
not infer a hidden keyboard from one false signal. After Back, it samples fresh
device state with a bounded settling interval and permits rail navigation only
when both `mInputShown=false` and `mIsInputViewShown=false` are present. A
non-converging state remains a truthful device-gate rejection.
