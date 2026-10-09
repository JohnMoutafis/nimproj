# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- `ProjError` (of `CatchableError`), carrying PROJ's numeric error code in `errno`, or 0 when the failure had none.
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
