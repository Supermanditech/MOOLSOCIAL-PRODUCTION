# C17H UIAutomator clipped rail bounds / adb input-space mismatch

UIAutomator reported Buy/Wholesale bounds centered at `(280,1376)`. Passing that point directly to `adb input tap` did not reach Wholesale; the next live inventory showed Social/Shorts. The hierarchy root ends at y=1442 while screenshots are 1600 pixels high and the fixed main rail continues below the hierarchy's clipped boundary.

No destination evidence was saved from the mismatched tap. Further bottom-rail navigation requires a measured physical-display/application-viewport transform and post-tap semantic confirmation before capture or naming.
