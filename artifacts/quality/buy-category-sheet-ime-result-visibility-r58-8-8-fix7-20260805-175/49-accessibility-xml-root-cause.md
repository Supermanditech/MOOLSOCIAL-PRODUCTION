# Android editable-field accessibility XML root cause

The legacy `adb shell uiautomator dump` format is lossy for Flutter text fields
on this Android 13 OPPO. It serializes `text` and `content-desc` but not
`AccessibilityNodeInfo.hintText`, then calculates `NAF=true` without considering
that omitted hint.

Flutter 3.44.6 engine source at
`engine/src/flutter/shell/platform/android/io/flutter/view/AccessibilityBridge.java`
lines 1113-1117 proves the Android bridge behavior: an `IS_TEXT_FIELD` node
receives its current value through `setText`; on API 28+ its label plus hint are
joined by `getTextFieldHint()` and written through `setHintText`. Non-text-field
nodes instead receive `setContentDescription`. The OPPO is API 33, so an empty
field is expected to have empty XML `text`/`content-desc` while TalkBack reads
the separately populated `hintText`.

Therefore the initial XML-only FIX5/FIX6/FIX7 classifier was invalid. The
preserved XML and provisional rejection records are not deleted. FIX7 continues
because it provides stronger explicit editable ownership; its decisive device
accessibility evidence is the read-only UiAutomator probe
`47a-AccessibilityHintProbe.java`, which reads the underlying
`AccessibilityNodeInfo.getHintText()` and action list directly.
