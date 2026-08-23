# C10C const Semantics compile failure

The active Flutter SDK rejected a const `Semantics` construction in the compact Buy header integration. The accessibility wrapper remains present but non-const, with only its eligible leaf child const. Focused compilation is the enforcing gate.
