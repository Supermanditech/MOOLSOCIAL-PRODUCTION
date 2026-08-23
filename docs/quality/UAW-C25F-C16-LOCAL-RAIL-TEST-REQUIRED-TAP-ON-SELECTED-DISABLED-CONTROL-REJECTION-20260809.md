# C25F C16 selected local control tap assertion rejection

- Date: 2026-08-09
- First observed file: Eat C16D
- Status: registered before bounded group retry

The first migrated Eat C16D test required `SemanticsAction.tap` on both local controls. The currently selected Order Food control is intentionally disabled as a redundant navigation target, so it exposes selected/current semantics but no tap action. The unselected Book Table control remains a direct one-tap action.

The bounded C16D/C16F/C16G correction validates 44 px sizing for every control and tap semantics only for unselected destinations. It does not weaken direct reachability or change runtime behavior.
