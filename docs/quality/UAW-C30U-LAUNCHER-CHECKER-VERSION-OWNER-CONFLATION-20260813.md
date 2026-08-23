# C30U launcher checker version-owner conflation

## Incident

The wrapper checker required the exact full version-name literal inside the
founder launcher. The launcher verifies candidate id, version code and r60.46;
the machine state gate owns the full version name, so this was a false failure.

## Permanent prevention

Check secure input and selected state in the launcher, full candidate identity
in the machine gate, and dynamic version propagation in the wrapper.

No build or external mutation occurred.
