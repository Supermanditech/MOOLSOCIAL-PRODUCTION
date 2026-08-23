# C17H semantic capture stale starting-state rejection

The first artifact-helper run expected `Earn Today, current` from an earlier inventory, but the device state had changed before invocation. The helper timed out and saved no q-prefixed evidence.

Every subsequent semantic session begins with an inventory-only live hierarchy read and navigates only through a semantic target exposed by that same current state. A destination must appear selected in two consecutive dumps before capture.
