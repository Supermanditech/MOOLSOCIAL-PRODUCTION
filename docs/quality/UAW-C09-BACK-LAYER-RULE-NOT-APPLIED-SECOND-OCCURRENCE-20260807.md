# C09 Back-layer rule missed in second occurrence

Date: 7 August 2026

After REG-20260807-141 was registered and the first Social -> Mool -> Buy test
was corrected, the next Chat/deeper-return test retained the same one-Back-to-
Social assumption. Its first Back correctly showed Mool Home, so the Social
assertion failed. Twenty-five other Screen 04 tests passed.

REG-20260807-144 records the failure to apply a newly registered prevention to
all same-file occurrences before retry. The second journey now asserts Mool on
the first Back and exact Social Feed on the second.
