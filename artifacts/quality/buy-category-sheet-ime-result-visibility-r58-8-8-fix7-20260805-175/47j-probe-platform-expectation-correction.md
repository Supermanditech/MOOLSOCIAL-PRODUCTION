# Direct-hint probe platform-expectation correction

The first self-navigating probe reached the exact OPPO node and proved the
correct hint, editable flag, click and set-text actions. It failed only because
the evidence helper expected an empty field value as `""`; Android returns
`null` when no current text exists. It also inspected ordinary `ACTION_FOCUS`,
whereas TalkBack uses `ACTION_ACCESSIBILITY_FOCUS` for traversal.

The rerun normalizes only a null current value to empty and requires
accessibility-focus, click and set-text actions. No candidate source, APK or
device setting changed.
