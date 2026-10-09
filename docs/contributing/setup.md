# Development setup

## Prerequisites

| Requirement | Version | Why |
|---|---|---|
| Nim | ≥ 2.0.0 | ORC is the default memory manager; no 2.2-only features are used |
| PROJ | ≥ 9.0 | the `PJ_*` API generation — `proj_api.h` is gone since 8.0, so there is exactly one API to bind |
| `proj.db` | ships with PROJ | without it, no EPSG code resolves and most tests fail |

Install PROJ per platform — see
[Installation](../getting-started/installation.md).

## Clone and check

```sh
git clone https://github.com/JohnMoutafis/nimproj
cd nimproj

nim --version              # >= 2.0.0
pkg-config --modversion proj   # >= 9.0 on Linux/macOS
ls /usr/share/proj/proj.db     # or the platform equivalent

nimble test
```

If `nimble test` fails at link time with undefined `proj_*` symbols, PROJ is not
on the linker's path; see [Installation](../getting-started/installation.md) for
the `LIBRARY_PATH` / `C_INCLUDE_PATH` settings used on macOS.

## Building the docs

```sh
nimble docs                    # API reference into src/htmldocs/
pip install mkdocs-material
nimble docsSite                # builds site/; must pass --strict
```

`nimble docs` needs a working `libproj`, because `nim doc` type-checks the
package — including Layer 0, which links against it.

## Day-to-day

```sh
nim r --hints:off tests/t_proj_abi_smoke.nim   # single test file
nimble test                                    # everything
nimpretty src/nimproj/*.nim                    # before committing
```
