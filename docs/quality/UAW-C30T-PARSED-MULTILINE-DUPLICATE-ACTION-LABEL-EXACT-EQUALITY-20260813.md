# C30T parsed multiline duplicate Feed action label

Date: 2026-08-13
Disposition: resolved harness mistake; stopped before product action

## What happened

The Feed share-copy harness parsed the current UIAutomator hierarchy but
required `content-desc` to equal `Share`. Flutter exposed the clickable action
as two semantic lines (`Share`, `Share`), and the viewport contained Share
nodes from two different cards. The assertion therefore stopped with zero
exact matches even though the retained hierarchy proved both controls.

## Permanent rule

Parsed accessibility values are normalized into trimmed lines. The harness
matches `Share` as a complete semantic line, requires enabled/clickable state,
and selects the intended card using its retained bounds and card context.
Duplicate labels never justify a blind coordinate.

The stopped attempt made no tap, external share or clipboard read.
