# C16 — r60.15 global subaction design-system founder rejection

## Candidate disposition

The founder rejected the visual system of checksum-matched OPPO candidate
`1.0.0-r60.15` (`2026080815`), SHA-256
`94443C63382205E5E47DC7BBA2D23D98C579B5AADB5C34ADBC443448E1EB0968`.
The functional navigation connection and predecessor evidence remain
preserved, but r60.15 is not a founder-approved subaction design candidate.

## Founder findings

- Social, Buy, Eat, Ride, Book and Work do not share one professional visual
  language for subaction typography, icons, spacing, selection and motion.
- the current family layer hinders or visually displaces destination content,
  especially Buy product grids;
- Buy still reads as a left-to-right Shop/Wholesale/Medicine/Orders strip;
- two-action families such as Eat, Book and Work stretch too widely and do not
  use a compact, standardized composition;
- Ride repeats the inconsistent spacing and text-scale problem;
- main-action and subaction switches do not consistently feel native to one
  persistent app shell; the user can feel as though a new unrelated page has
  replaced the current context;
- the full global bottom rail must remain visually anchored and native to each
  destination while content and local selection move behind it;
- passing a 44px geometry and wave test did not prove production-quality UI/UX.

## Existing device evidence

- Buy Shop:
  `artifacts/quality/uaw-personal-mvp-transparent-gradient-wave-family-connection-fix1-c15-r60-15-20260808-01/15-02-social-default.png`
- Buy Wholesale:
  `artifacts/quality/uaw-personal-mvp-transparent-gradient-wave-family-connection-fix1-c15-r60-15-20260808-01/15-03-buy-wholesale.png`
- Eat Order Food and Book Table:
  `15-04-eat-default.png` and `15-05-eat-book-table.png` in the same artifact
  directory.
- Ride Bike:
  `15-06-ride-bike.png` in the same artifact directory.

The C16 predecessor audit must capture fresh Social, Book and Work states and
complete the full selected-state matrix before visual design selection.

## Required correction

C16 registers one shared adaptive native Flutter owner plus Social, Buy, Eat,
Ride, Book and Work conformance children. Variable counts must be handled by a
professional adaptive layout rather than overstretching two actions or adding
fabricated filler. Any genuinely new subaction requires a documented customer
outcome, truthful route and state owner, scope approval and acceptance tests.
Main-action and subaction movement must retain one native shell: the global
rail keeps its approved order, meaning and visual anchor while destination
identity and local content transition finitely behind it without a page-reset
or unrelated-route feeling.

No C16 build or install is open until all host gates and two affected cycles
pass. r60.15 remains installed and preserved as the rejected predecessor.
