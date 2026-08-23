# C24B3 Buy custom-painter redundant-wordmark rejection — 2026-08-09

C24B3 removed the Buy widget brand tile and its MoolSocial semantics, yet the
header custom painter still drew animated and settled `Mool`/`Social` text.
Those pixels are outside the widget tree, so focused key/semantics tests did
not catch the visual regression and the screen could appear unchanged.

The correction removes both wordmark painter calls and their private drawing
methods. Contextual first-party visuals and truthful actions remain; the single
connected MoolSocial launcher owns persistent brand navigation.
