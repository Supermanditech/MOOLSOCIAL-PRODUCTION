# C29O dynamic rail-key source-shape false rejection

Date: 2026-08-11

The first C29O source-gate run required the exact inline syntax
`Key('screen04-rail-shorts')`. The focused widget test stores `shorts` in its
journey map and constructs `Key('screen04-rail-${journey.key}')` in the executed
loop. The source gate therefore rejected equivalent tested behavior.

Permanent prevention: assert stable journey literals, the dynamic key
construction and the executed behavioral test owner; never require one
interchangeable inline Dart construction.
