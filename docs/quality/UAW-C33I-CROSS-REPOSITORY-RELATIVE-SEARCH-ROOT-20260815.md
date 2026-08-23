# C33I cross-repository relative-search root regression

Date: 2026-08-15
Ticket: `UAW-C33I-SCREEN03-PASSWORDLESS-EMAIL-LINK-REFERENCE-SUCCESSOR`

## Failure

A read-only `rg` command ran from the screenbook while also naming production-repository-relative owners. The screenbook lookup succeeded, but the production paths were unresolved and the command exited 1. No file was changed.

## Root cause

Two repository-relative searches with different owning roots were combined under one working directory.

## Permanent prevention

Run each repository-relative search from the repository that owns the path, or use an already verified absolute path. Never aggregate production and screenbook relative paths under one working directory.
