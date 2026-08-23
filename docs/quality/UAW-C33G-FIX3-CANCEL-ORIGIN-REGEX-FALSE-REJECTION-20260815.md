# UAW C33G FIX3 cancel-origin regex false rejection

The first C33G FIX3 gate execution rejected the Create cancellation-origin assertion even though the Social consumer contains the intended exact owner twice. The failed gate stopped before any product test, build, Play or device action.

The correction defines the exact Dart fragment as a PowerShell single-quoted literal and passes it through `Regex.Escape` before counting. Handwritten regex is no longer used for this fixed fragment.
