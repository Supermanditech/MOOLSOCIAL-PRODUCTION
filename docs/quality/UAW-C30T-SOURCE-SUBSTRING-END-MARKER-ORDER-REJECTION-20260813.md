# UAW C30T source-substring end-marker order rejection — 2026-08-13

Before running the new upload-reachability source test, inspection showed its
end marker (`void _explainMoolSocialReplyGate`) occurs before `_buildCreate`.
The proposed substring would therefore throw a range error. No test attempt
ran with the invalid range. The end marker is corrected to the next literal
owner, `String get _publicAuthorName`.
