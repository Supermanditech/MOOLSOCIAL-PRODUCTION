# C24E Salon Facial price expectation rejection — 2026-08-09

The first focused Salon test guessed a ₹599 Facial price. The retained
`BookSession.chooseSalonService` owner truthfully sets Facial to ₹499. No
production price changed.

The corrected test binds to ₹499 in session state and the rendered provider
semantics. Reference-screen pricing is not copied into the MVP. This failed
invocation counts as no qualification cycle.
