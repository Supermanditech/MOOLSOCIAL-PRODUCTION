# C33D C16E/C16F surface-size and MediaQuery mismatch

The bounded diagnostic measured the mounted C16E production shell at a
152-pixel local rail with 54-pixel Mool, family-root and Chat controls. A true
320dp view selects 44-pixel fixed controls and should leave 182 pixels.

The historical C16E/C16F harnesses use `binding.setSurfaceSize` but do not set
`tester.view.physicalSize` and `devicePixelRatio`. In the current Flutter test
environment, layout constraints and responsive `MediaQuery` inputs therefore
disagree.

REG-2315 requires both harnesses to own an explicit 320x568 view at DPR 1 and
to reset it. The diagnostic print is temporary and must be removed before
qualification.
