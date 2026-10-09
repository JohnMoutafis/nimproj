# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] - 2026-10-13

v0.2.0 ships `Crs` — the coordinate reference system type.

### Added

**`Crs` — the CRS type**

- `Crs` with `initCrs(ctx, source)`, raising `CrsError` when PROJ rejects the
  definition.
- The predicates `isGeographic`, `isProjected`, `isBound`, `isCompound`,
  `isDeprecated` and `isEquivalentTo`.
- The accessors `name`, `idAuth`, `idCode` and `subCrs`.
- The output formats `toWkt`, `toProjString`, `toProjJson` and `$`.
- The ownership model: a `Crs` owns its `PJ*` — `=copy` deep-copies through
  `proj_clone`, `=destroy` frees through `proj_destroy` — so a copied `Crs`
  never double-frees.

**Layer 0 — the ABI module**

- The C-derived enums `PROJType` (`PJ_TYPE`), `PROJWktType` (`PJ_WKT_TYPE`),
  `PROJStringType` (`PJ_PROJ_STRING_TYPE`) and `PROJComparisonCriterion`
  (`PJ_COMPARISON_CRITERION`), plus the `Wkt2_2018` / `Wkt2_2018Simplified`
  aliases for the 2019 WKT variants.

**Tests**

- `tests/t_crs.nim` — the differential harness: the library's serialisation
  compared byte-for-byte against the system `projinfo` CLI, invoked at test
  time so the check follows the installed PROJ and EPSG database.

### Fixed

- **Windows build: `ProjError.errno` collided with the C `errno` macro.** The
  field emitted `int errno;` into the generated C, which `<errno.h>`'s
  `#define errno (*__errno_location ())` rewrote into a function call — MSVC
  rejected it with `C2032: _errno: function cannot be member of struct` and
  `C2059: syntax error`. Linux and macOS were unaffected because nothing in
  their translation unit pulls in `<errno.h>`; MSVC's `<stdlib.h>` does. The
  field is renamed to `projErrno`. This is a breaking change to the field name
  for anyone who read it directly — the exception type and its catchability
  are unchanged.
- `tests/t_errno_macro.nim` forces `<errno.h>` into the translation unit on
  every platform (`-include` for gcc/clang, `/FI` for MSVC), so a
  macro-colliding field name fails locally instead of on the Windows matrix
  entry. The guard deliberately does not name the field, so a rename-back
  fails at the C compile rather than with a Nim "undeclared field" error.

---

## [0.1.0] - 2026-10-09

First release. v0.1.0 ships the package scaffolding, the Layer-0 bindings for
`proj.h`, the `ProjContext` lifecycle and the `ProjError` hierarchy.

### Added

**Package scaffolding**

- `nimproj.nimble` with `version = "0.1.0"`, `srcDir = "src"`, and `requires "nim >= 2.0.0"`.
- `config.nims`, switching to `--cc:vcc` on Windows so the MSVC toolchain links the vcpkg `libproj` import library.
- CI on Linux, macOS and Windows, on `stable` and `devel` Nim (`.github/workflows/ci.yml`), plus a docs workflow that builds the site with `mkdocs build --strict` and deploys on `release: published`.
- The documentation site (`mkdocs.yml`) and the user guide under `docs/`.
- `LICENSE` (MIT).

**Layer 0 — the ABI module**

- Bindings for `proj.h` in `src/nimproj/private/proj_abi.nim`, the only place `proj_*` bindings are declared.

**`ProjContext` — the context lifecycle**

- `initProjContext()` creates a context, raising `ProjInitError` when PROJ returns a nil handle — in practice `libproj` is missing, or a different one than expected was linked.
- `ProjContext` is non-copyable: `=copy` is declared `{.error.}`, so a second owner is a compile error rather than a comment asking you not to make one.
- `=destroy` calls `proj_context_destroy` deterministically under ORC, and is a no-op for a moved-from value.
- `projVersion()` and `projVersionString()` are library-level and need no context.
- `lastError()` returns PROJ's message for the most recent failure on that context, or `""` when the last operation succeeded — PROJ clears its error code on success, so it means "the last operation", not "any operation ever".

**Error types**

- `ProjError` (of `CatchableError`), carrying PROJ's numeric error code in `errno`, or 0 when the failure had none. (Renamed to `projErrno` in the next release — see [Unreleased].)
- `ProjInitError` — raised when a context cannot be created.
- `CrsError`, `TransformError` and `GeodError` — declared and part of the published contract, raised from v0.2.0, v0.3.0 and v0.7.0 respectively. A caller catching `ProjError` is complete today and stays complete when the subtypes start arriving.

**Tests**

- `tests/t_proj_abi_smoke.nim` — the Layer-0 smoke test: the library links, the header parses, a context can be created and destroyed.
- `tests/t_context.nim` — the `ProjContext` suite: construction, the version functions, `lastError`, and the error paths.
- `tests/compile_fail/noncopyable.nim` — the negative compile check asserting `ProjContext` cannot be copied. It needs a full `nim c`, not `nim check` or a `compiles()` probe: Nim raises the `=copy` diagnostic in the destructor-injection pass, which neither reaches.
- `nimble test` walks `tests/` recursively for `t_*.nim`, runs the compile-fail check separately, and counts what actually ran — `nim r` on an empty module exits 0, so a scaffolded test file that was never written would otherwise report a green run.

### Notes

- PROJ ≥ 9.0 and its `proj.db` are system dependencies, never vendored. A
  missing PROJ is a link error, not a degraded mode.
