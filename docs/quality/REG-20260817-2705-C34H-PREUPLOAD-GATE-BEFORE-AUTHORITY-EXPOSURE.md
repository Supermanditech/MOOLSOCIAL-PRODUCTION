# C34H preupload gate invoked before upload-authority exposure

Date: 2026-08-17 IST

## Mistake

The C34H `preupload` gate was invoked immediately after the passing
`postbuild` gate while upload authority was still truthfully held. It failed
closed at counts `1/0/0/0`; no browser or Play write had occurred.

## Root cause

The postbuild artifact qualification and the later explicit projection of the
founder's one-time Internal Testing authority were treated as one implicit
step even though the state machine declares them separately.

## Permanent prevention

After postbuild, first verify the retained artifact, project only the exact
founder-authorized upload fields in mutable state and aggregate, parse both
owners, and only then invoke `preupload`. A held-authority rejection is not
permission to retry the gate without that transition.
