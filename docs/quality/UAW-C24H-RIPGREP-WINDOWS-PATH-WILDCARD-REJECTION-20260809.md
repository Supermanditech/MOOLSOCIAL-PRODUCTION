# C24H ripgrep Windows path wildcard rejection

Date: 2026-08-09
Regression: `REG-20260809-745-C24H-RIPGREP-WINDOWS-PATH-WILDCARD-USED-AS-INPUT`

The first C24H evidence inventory passed wildcard-bearing Windows paths as
literal ripgrep inputs. Windows rejected the path syntax. The retry searches
the real `docs/quality` directory and filters filenames using `-g` patterns.
