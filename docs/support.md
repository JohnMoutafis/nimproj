# Support policy

## Versions

| Component | Supported | Notes |
|---|---|---|
| Nim | ≥ 2.0.0 | CI runs `stable` and `devel`; `devel` failures are reported, not blocking |
| PROJ | ≥ 9.0 | one API generation: `proj_api.h` was removed in 8.0, so there is no legacy branch to carry |
| `proj.db` | ships with PROJ | required; there is no fallback registry |

Everything the package binds was verified present in `libproj` 9.7.1 on
2026-10-08. Where a function arrived later than 9.0, the version it needs is
noted in its documentation.

## Platforms

| Platform | Status |
|---|---|
| Linux (Debian/Ubuntu) | supported, CI-tested |
| macOS | supported, CI-tested |
| Windows (MSVC + vcpkg) | supported, CI-tested; the least predictable entry, and the first place a linking regression appears |

## What "supported" means

- The API in the released version does not change incompatibly before 2.0.
- A behaviour difference between two supported PROJ versions is *documented*, not
  papered over. Operation selection near datum boundaries is the usual case: a
  user on PROJ 9.9 may get a different — better — coordinate operation than a
  user on 9.7.1, because the candidate list comes from `proj.db`.
- Fixtures record the PROJ release they were generated with, so this is visible
  rather than surprising.

## Reporting

Open an [issue](https://github.com/JohnMoutafis/nimproj/issues/new) with:

- `projinfo --version`-equivalent output, i.e. your PROJ release
  (`proj` or `projinfo` prints it), and `nim --version`
- the smallest program that shows the problem
- for numeric problems: the expected coordinate **and** the command that
  produced it (`cs2cs` or `projinfo`), so the claim is checkable against the
  engine rather than against recollection
