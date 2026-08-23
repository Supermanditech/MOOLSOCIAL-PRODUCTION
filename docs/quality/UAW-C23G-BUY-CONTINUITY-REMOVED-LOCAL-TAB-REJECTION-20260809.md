# C23G Buy continuity removed local-tab rejection

The isolated Buy file passed its migrated Home and Back paths, then rejected
two remaining `buy-local-tab-medicine` and `buy-local-tab-wholesale` taps.
Those local rail controls are intentionally absent in C23. REG-20260809-578
migrates both outcomes to destination Mool launcher -> exact Home Buy
subaction, using visible-target preconditions. No host cycle or APK authority
passed.
