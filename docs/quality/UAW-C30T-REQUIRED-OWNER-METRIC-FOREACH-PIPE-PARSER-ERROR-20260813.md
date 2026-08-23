# C30T required-owner metric foreach-pipe parser error

## Incident

The first compact line/byte inventory for required owners attempted to pipe
directly from an unwrapped PowerShell `foreach` statement to `Format-Table`.
PowerShell rejected the command with an empty-pipe-element parser error.

## Impact

The command did not read the required owner contents and produced no admissible
owner evidence. It changed no repository, Git, build, service or device state.

## Prevention

Accumulate the metric objects in an explicit `$results` array within the loop,
then format that array after the loop. Any parser error is treated as zero
evidence and registered before retry.
