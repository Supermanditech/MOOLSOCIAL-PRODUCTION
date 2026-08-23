# C10C affected-test inventory matched capture artifacts

A broad `candidate` path filter matched hundreds of PNG capture artifacts as well as Dart tests, and the output was truncated. Test discovery now filters to `.dart` paths first, uses exact basenames, and bounds displayed results. The noisy partial listing is not qualification evidence.
