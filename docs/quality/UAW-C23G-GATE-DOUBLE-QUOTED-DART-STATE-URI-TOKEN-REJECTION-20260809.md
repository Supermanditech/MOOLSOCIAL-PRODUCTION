# C23G gate Dart token interpolation rejection

Before executing the updated gate, review found the literal Dart token
`${state.uri}` inside a PowerShell double-quoted string. That would interpolate
`$state` and make the check untruthful. REG-20260809-583 switches the check to a
single-quoted PowerShell literal with doubled embedded Dart quotes. The faulty
gate was never executed and no qualification result changed.
