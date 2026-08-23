# REG-20260817-2746: C34L transaction-fixture OrderedDictionary Clone

## Truthful event

The first executable PowerShell 7 lifecycle fixture stopped before any
transition because its fixture constructor called `.Clone()` on the ordered
count and authority dictionaries. `System.Collections.Specialized.OrderedDictionary`
does not expose that method. The transaction sub-agent stopped without retry or
correction.

All three assigned transaction scripts had parsed in PowerShell 7, and the
implementation memory gate had passed before the fixture. Only a unique
temporary fixture was created and cleaned by that test. No real candidate
state, source seal, cycle, AAB, device, Google Play, credential, secret,
deployment, or external state changed.

## Root cause

The fixture helper assumed PowerShell ordered dictionaries implement the same
clone surface as a hashtable or another mutable collection.

## Prevention

- Build each fixture object from an explicit newly constructed ordered
  projection of the eight counts and four authorities.
- Assert detailed and aggregate objects are distinct references before the
  first transition invocation.
- Rerun the lifecycle fixture from a new unique root only after registration
  and the bounded constructor correction.

## Candidate consequence

C34L remains selection-only at zero release actions. The failure occurred
before transition execution, so it is zero transaction qualification evidence.
