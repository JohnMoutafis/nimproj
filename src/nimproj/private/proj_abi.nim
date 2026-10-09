## PROJ Application Binary Interface (ABI)
## Raw importc bindings for libproj — DO NOT use directly.
## Every proc is declared with the C symbol name verbatim, so it can be checked
## against `proj.h` by eye and links without an `importc` rename.

# ── Linkage ───────────────────────────────────────────────────────────────────
# MSVC's link.exe has no `-l<name>` option — it warns D9002 and skips it, so
# every proj_* symbol stays unresolved. Name the import library directly
# instead; the linker resolves it from LIB, which vcpkg sets (triplet
# x64-windows → lib/proj.lib + bin/proj.dll). gcc/clang — Linux, macOS, MinGW on
# Windows — use the `-l` form. Same pattern as Nim's stdlib
# (lib/ioselects/ioselectors_select.nim: ws2_32 vs ws2_32.lib).
when defined(vcc) or defined(clang_cl):
  {.passL: "proj.lib".}
else:
  {.passL: "-lproj".}

# ── Shared pragmas ────────────────────────────────────────────────────────────
# One pragma group for every binding: no Nim exception crosses the boundary and
# no unsafe GC access happens, asserted at compile time. `header` sits on every
# declaration (via the push below) so the C compiler checks the ABI against the
# real prototype — a declaration without it is a declaration nothing verifies.
{.pragma: projImport, importc, cdecl, raises: [], gcsafe.}

{.push header: "proj.h".}

# ── Opaque handle types ───────────────────────────────────────────────────────
# Nim-side names, not the C typedefs: `PROJContext` and `PROJ_CONTEXT` are the
# *same* identifier as the public `ProjContext`, because Nim ignores case and
# underscores after the first letter. `distinct pointer` keeps the compiler from
# accepting one where the other belongs. A `PROJContextHandle` is not
# thread-safe when shared: use one per thread.
type
  PROJContextHandle* = distinct pointer
  PROJ*              = distinct pointer

# ── Value types ───────────────────────────────────────────────────────────────
type
  PROJInfo* {.importc: "PJ_INFO", bycopy.} = object
    ## Library-level information, as returned by `proj_info`.
    major*: cint
    minor*: cint
    patch*: cint
    release*: cstring
    version*: cstring

# ── Context lifecycle ─────────────────────────────────────────────────────────
proc proj_context_create*(): PROJContextHandle {.projImport.}
proc proj_context_destroy*(ctx: PROJContextHandle): PROJContextHandle {.projImport, discardable.}

# ── Library information ───────────────────────────────────────────────────────
proc proj_info*(): PROJInfo {.projImport.}

# ── Object creation ───────────────────────────────────────────────────────────
proc proj_create*(ctx: PROJContextHandle; definition: cstring): PROJ {.projImport.}
  ## Creates an object from a PROJ string, WKT, PROJJSON or authority code.
  ## Returns nil on failure — check `proj_context_errno`, not this return.

# ── Errors ────────────────────────────────────────────────────────────────────
proc proj_context_errno*(ctx: PROJContextHandle): cint {.projImport.}
proc proj_context_errno_string*(ctx: PROJContextHandle; err: cint): cstring {.projImport.}
  ## Borrowed: owned by `ctx`, copied out by the caller, never freed.

{.pop.}
