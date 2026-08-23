# Temporary prototype persistent main-action rail duplication rejection

Date: 2026-08-09

The temporary prototype kept Social, Shop, Food, Travel, Care and Work in a
persistent top rail while also rendering destination subactions in the bottom
rail. The two always-visible navigation layers consumed product visibility and
split one-handed navigation ownership.

Root cause: global family discovery and local destination switching were both
treated as persistent page chrome instead of assigning each to one clear
interaction owner.

Correction contract: the compact Mool control opens the six-family menu. The
top family rail is absent. The bottom rail starts with the selected family's
Home and includes every truthful family subaction in a horizontally scrollable
44px-or-larger row with a visible initial overflow cue. Selecting a family
lands directly on its transaction-ready Home; selecting a local action is one
tap and never required before tapping a product or service in the Home feed.

No Flutter source, accepted screenbook, APK, installed OPPO state or protected
runtime was changed by this temporary-HTML rejection.
