# C10C repeated Help tap edit targeted the wrong occurrence

The test contained two identical Help-tap lines. A context-light patch changed the first line to system Back, returning to catalogue before Help was asserted open. The corrected sequence opens Help, asserts assist, then uses system Back to restore the exact tracking state. Repeated interaction edits now include surrounding state assertions.
