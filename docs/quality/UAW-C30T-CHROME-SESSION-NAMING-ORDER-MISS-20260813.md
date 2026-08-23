# C30T Chrome session naming order miss

Date: 2026-08-13

The read-only Chrome fallback listed visible open tabs before assigning the required task-specific session name. It did not claim, navigate or change any tab.

Permanent prevention: name every Chrome automation session before opening, claiming, navigating or inspecting tabs, then use only methods documented by the connected browser runtime.
