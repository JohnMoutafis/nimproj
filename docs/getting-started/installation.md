# Installation

nimproj links the system PROJ. There is no vendored copy and no bundled
fallback — a missing PROJ is a link error, not a degraded mode.

## Requirements

- Nim ≥ 2.0.0
- PROJ ≥ 9.0: the development headers (`proj.h`, `geodesic.h`) plus the library
- `proj.db`: the CRS registry. PROJ ships it; without it no EPSG code resolves

## Linux (Debian/Ubuntu)

```sh
sudo apt-get install libproj-dev proj-data
pkg-config --modversion proj     # expect >= 9.0
```

`libproj-dev` 9.7.1-1 and `proj-data` 9.7.1-1 are current as of 2026-10; the
package names are stable from PROJ 6 onwards.

## macOS (Homebrew)

```sh
brew install proj
export LIBRARY_PATH="$(brew --prefix proj)/lib"
export C_INCLUDE_PATH="$(brew --prefix proj)/include"
export PROJ_DATA="$(brew --prefix proj)/share/proj"
```

The exports matter: Homebrew's `proj` is not on the default linker search path,
and its `proj.db` is not where PROJ looks by default.

## Windows (vcpkg)

```powershell
vcpkg install proj --triplet x64-windows
$lib  = Join-Path $env:VCPKG_INSTALLATION_ROOT "installed\x64-windows\lib"
$bin  = Join-Path $env:VCPKG_INSTALLATION_ROOT "installed\x64-windows\bin"
$inc  = Join-Path $env:VCPKG_INSTALLATION_ROOT "installed\x64-windows\include"
```

with `LIB`, `INCLUDE` and `PATH` extended accordingly, and MSVC as the
toolchain — `config.nims` switches to `--cc:vcc` on Windows for exactly this
reason. Locate `proj.db` under the vcpkg tree and point PROJ at it:

```powershell
Get-ChildItem -Path $env:VCPKG_INSTALLATION_ROOT -Filter proj.db -Recurse |
  Select-Object -First 1 -ExpandProperty DirectoryName
# set PROJ_DATA to that directory
```

Windows C++ builds must match the vcpkg triplet's runtime, and the DLL must be
on `PATH` when tests run.

## Environment variables

| Variable | Use |
|---|---|
| `PROJ_DATA` | where the CRS registry and grids live. **Set this one** — `PROJ_LIB` still works but `libproj` reports it as deprecated and slated for removal |
| `PROJ_NETWORK` | grid download over the network. Left **off** by default: a transform that fetches from a CDN gives different answers depending on connectivity |

## Verify

```sh
pkg-config --modversion proj          # >= 9.0
projinfo EPSG:32633 -q -o PROJ        # +proj=utm +zone=33 +datum=WGS84 ...
```

Then the package itself:

```nim
import nimproj

let ctx = initProjContext()
echo projVersion()          # 9.7.1
```

## Troubleshooting

| Symptom | Cause |
|---|---|
| `undefined reference to 'proj_context_create'` | PROJ is not on the linker path — see the macOS/Windows exports above |
| `proj_create: Cannot find proj.db` (on stderr) | `PROJ_DATA` is unset or wrong; PROJ logs this itself before any Nim code runs |
| `Invalid PROJ string syntax` for a valid EPSG code | same cause — the code cannot be resolved without the registry |
| Link succeeds, transform gives nonsense | the wrong `libproj` was picked up: check `ldd` / `otool -L` against `pkg-config --variable=libdir proj` |
