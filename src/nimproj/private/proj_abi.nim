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

# ── Enums ─────────────────────────────────────────────────────────────────────
# `PJ_TYPE` has two abstract members (`Crs = 8`, `GeographicCrs = 11`) that
# `proj_get_type` never returns. The deprecated C aliases (`PJ_WKT2_2018`)
# cannot be enumerators — Nim enums are closed sets of distinct values — so
# they live in the `const` below.
type
  PROJType* {.importc: "PJ_TYPE", header: "proj.h", pure.} = enum
    Unknown = 0
    Ellipsoid = 1
    PrimeMeridian = 2
    GeodeticReferenceFrame = 3
    DynamicGeodeticReferenceFrame = 4
    VerticalReferenceFrame = 5
    DynamicVerticalReferenceFrame = 6
    DatumEnsemble = 7
    Crs = 8
    GeodeticCrs = 9
    GeocentricCrs = 10
    GeographicCrs = 11
    Geographic2DCrs = 12
    Geographic3DCrs = 13
    VerticalCrs = 14
    ProjectedCrs = 15
    CompoundCrs = 16
    TemporalCrs = 17
    EngineeringCrs = 18
    BoundCrs = 19
    OtherCrs = 20
    Conversion = 21
    Transformation = 22
    ConcatenatedOperation = 23
    OtherCoordinateOperation = 24
    TemporalDatum = 25
    EngineeringDatum = 26
    ParametricDatum = 27
    DerivedProjectedCrs = 28
    CoordinateMetadata = 29

  PROJWktType* {.importc: "PJ_WKT_TYPE", header: "proj.h", pure.} = enum
    Wkt2_2015 = 0
    Wkt2_2015Simplified = 1
    Wkt2_2019 = 2
    Wkt2_2019Simplified = 3
    Wkt1Gdal = 4
    Wkt1Esri = 5

  PROJStringType* {.importc: "PJ_PROJ_STRING_TYPE", header: "proj.h", pure.} = enum
    Proj5 = 0
    Proj4 = 1

  PROJComparisonCriterion* {.importc: "PJ_COMPARISON_CRITERION", header: "proj.h", pure.} = enum
    Strict = 0
    Equivalent = 1
    EquivalentExceptAxisOrderGeogcrs = 2

const
  Wkt2_2018* = Wkt2_2019
  Wkt2_2018Simplified* = Wkt2_2019Simplified

# ── Object lifecycle ──────────────────────────────────────────────────────────
proc proj_destroy*(p: PROJ): PROJ {.projImport, discardable.}

# ── ISO-19111 object functions ────────────────────────────────────────────────
proc proj_clone*(ctx: PROJContextHandle; obj: PROJ): PROJ {.projImport.}
proc proj_get_type*(p: PROJ): PROJType {.projImport.}
proc proj_get_name*(p: PROJ): cstring {.projImport.}
  ## Borrowed: owned by the PJ object, copied out with `$` before it is destroyed, never freed by the caller.
proc proj_get_id_auth_name*(p: PROJ; index: cint): cstring {.projImport.}
  ## Borrowed: owned by the PJ object, copied out with `$` before it is destroyed, never freed by the caller.
proc proj_get_id_code*(p: PROJ; index: cint): cstring {.projImport.}
  ## Borrowed: owned by the PJ object, copied out with `$` before it is destroyed, never freed by the caller.
proc proj_is_deprecated*(p: PROJ): cint {.projImport.}
proc proj_is_equivalent_to*(p: PROJ; other: PROJ; criterion: PROJComparisonCriterion): cint {.projImport.}
proc proj_as_wkt*(ctx: PROJContextHandle; p: PROJ; wktType: PROJWktType; options: pointer): cstring {.projImport.}
  ## Borrowed: owned by the PJ object, copied out with `$` before it is destroyed, never freed by the caller.
proc proj_as_proj_string*(ctx: PROJContextHandle; p: PROJ; projStringType: PROJStringType; options: pointer): cstring {.projImport.}
  ## Borrowed: owned by the PJ object, copied out with `$` before it is destroyed, never freed by the caller.
proc proj_as_projjson*(ctx: PROJContextHandle; p: PROJ; options: pointer): cstring {.projImport.}
  ## Borrowed: owned by the PJ object, copied out with `$` before it is destroyed, never freed by the caller.
proc proj_crs_get_sub_crs*(ctx: PROJContextHandle; crs: PROJ; index: cint): PROJ {.projImport.}
  ## OWNED: the one function here returning a `PJ*` the caller must `proj_destroy`

{.pop.}
