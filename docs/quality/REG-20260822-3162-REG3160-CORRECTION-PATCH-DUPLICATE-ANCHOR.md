# REG3162 - REG3160 correction patch duplicate anchor

## Classification

Registered patch rejection with zero registry mutation.

## Evidence

The correction patch repeated the REG3160 id as an unnecessary trailing context anchor. `apply_patch` rejected the complete patch atomically.

## Prevention

Use one unique scalar replacement block and one unique evidence-line append anchor. Do not repeat an already consumed id as trailing context.
