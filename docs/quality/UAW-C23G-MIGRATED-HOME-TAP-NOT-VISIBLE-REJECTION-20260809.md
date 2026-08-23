# C23G migrated Home tap visibility rejection

The post-migration batch reduced the required-suite failures from 16 to 3. One
confirmed failure tapped the C23 Eat family control while it was below the
800x600 test viewport. The control existed but the hit test missed, so Eat did
not open. REG-20260809-577 requires `ensureVisible`, settle, tap and route
validation for every migrated Home family or subaction interaction. No host
cycle or build/install authority passed.
