# C23C single Mool launcher shell preselection

C23C reuses the existing destination-shell owner and every `onOpenMool`
callback. A thin policy adapter replaces both rendered rails with one 56px
floating Home launcher; Home itself renders no bottom control. No route,
screen, backend, state or subaction is added. Build/install remain closed.
