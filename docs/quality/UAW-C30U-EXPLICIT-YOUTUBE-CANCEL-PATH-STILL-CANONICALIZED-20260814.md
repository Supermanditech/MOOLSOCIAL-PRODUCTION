# C30U explicit YouTube cancel path still canonicalized

The Social owner passed `/app/social?sub=videos`, but the JourneySession public
cancellation getter still returned `/app/social`. The second caller-side repair
was therefore insufficient.

The actual session storage/canonicalization owner must be inspected and fixed
before another test retry. No release mutation occurred.
