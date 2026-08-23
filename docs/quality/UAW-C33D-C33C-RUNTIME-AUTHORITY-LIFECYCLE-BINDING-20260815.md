# C33D C33C runtime-authority lifecycle binding

C33C correctly closes runtime-write authority after source qualification, but
its gate currently treats that closed flag as permanent. REG-2312 requires a
new exact runtime successor, so the C33C predecessor gate would reject the
valid C33D implementation window even when all live authorities remain closed.

REG-2313 requires an exact lifecycle binding: only active C33D may reopen the
bounded runtime source flag; after C33D qualification it must close again.
Backend, build, device, provider/external and secret authority remain false in
all states.
