# REG2681 — Git status prefix was treated as a wildcard

## Outcome

The bounded status summary used PowerShell wildcard matching for Git's literal `??` prefix and therefore reported an invalid tracked/untracked split. That category result is rejected.

## Prevention

Use `String.StartsWith('??')`, require the category sum to equal the total, and retain only scalar counts. This does not change C34F or authorize a successor or external action.
