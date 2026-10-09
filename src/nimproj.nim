## nimproj — Nim binding for the PROJ coordinate transformation library
## (`libproj`, `proj.h` + `geodesic.h`).
##
## Public API re-exports. Internal modules (``private/``) are intentionally
## **not** re-exported.
## See also: the user guide at `docs/index.md`.
##
## v0.1.0 surface: the context lifecycle (`ProjContext`, `projVersion` /
## `projVersionString`) and the `ProjError` hierarchy. `Crs` lands in v0.2.0,
## `Transformer` in v0.3.0.

# ── Core ──────────────────────────────────────────────────────────────────────
import nimproj/errors
import nimproj/context

# ══════════════════════════════════════════════════════════════════════════════
# Public exports — only user-facing modules are listed here.
# `private/*` is internal and NOT exported.
# ══════════════════════════════════════════════════════════════════════════════

export errors
export context
