# REG3190 - Empty obsolete resource directory kept lint warning

## Classification

Registered final release-lint warning root cause with zero lint errors, APK,
install or device action.

## Evidence

After the obsolete v21 XML file was removed, `lintRelease` completed
successfully but its freshly written XML report still contained
`ObsoleteSdkInt`. Bounded readback proved
`app/src/main/res/drawable-v21` still existed physically with exactly zero
items, and lint located the warning on that empty directory.

## Prevention

When intentionally removing the last resource from an obsolete qualifier,
verify and remove the exact empty directory before final lint. Never recurse or
delete a nonempty resource directory; require item count zero and an exact
repository-confined path first.
