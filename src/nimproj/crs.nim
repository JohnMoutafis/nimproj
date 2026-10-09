## PROJ CRS wrapper.
## A `Crs` owns its `PJ*` and is freed deterministically by ORC.

import ./private/proj_abi
import ./context
import ./errors

export proj_abi.PROJType, proj_abi.PROJWktType, proj_abi.PROJStringType,
  proj_abi.PROJComparisonCriterion, proj_abi.Wkt2_2018,
  proj_abi.Wkt2_2018Simplified

# ── Crs type ──────────────────────────────────────────────────────────────────
type
  Crs* = object
    ctx: PROJContextHandle  ## Internal — not part of the stable API.
    handle: PROJ            ## Internal — owned; freed by `=destroy`.
    crsType*: PROJType

proc `=destroy`*(c: Crs) =
  ## Frees the owned `PJ*` through `proj_destroy`, deterministically, under
  ## ORC. A moved-from value has a nil handle, so this is a no-op for it.
  if cast[pointer](c.handle) != nil:
    proj_destroy(c.handle)

proc `=copy`*(dst: var Crs; src: Crs) =
  ## Deep-copies through `proj_clone`; a bitwise copy would double-free.
  if cast[pointer](src.handle) == nil:
    if cast[pointer](dst.handle) != nil:
      proj_destroy(dst.handle)
    dst.handle = PROJ(nil)
    dst.ctx = src.ctx
    dst.crsType = src.crsType
    return
  let cloned = proj_clone(src.ctx, src.handle)
  if cast[pointer](cloned) == nil:
    raise newException(CrsError,
      "proj_clone() returned nil — cannot copy CRS")
  if cast[pointer](dst.handle) != nil:
    proj_destroy(dst.handle)
  dst.ctx = src.ctx
  dst.handle = cloned
  dst.crsType = src.crsType

# ── Constructor ───────────────────────────────────────────────────────────────
proc initCrs*(ctx: ProjContext; source: string): Crs =
  ## Parses a CRS definition. `source` accepts an EPSG code, an `AUTH:CODE`,
  ## a compound `AUTH:CODE+CODE`, a URN, WKT1/WKT2, PROJJSON or a proj-string.
  ##
  ## Raises `CrsError` when the definition cannot be parsed or resolved.
  let handle = proj_create(ctx.handle, source.cstring)
  if cast[pointer](handle) == nil:
    let err = proj_context_errno(ctx.handle)
    raise (ref CrsError)(
      msg: "proj_create() failed: " & $proj_context_errno_string(ctx.handle, err),
      projErrno: err)
  return Crs(ctx: ctx.handle, handle: handle, crsType: proj_get_type(handle))

# ── Accessors ────────────────────────────────────────────────────────────────
proc name*(c: Crs): string =
  ## Returns the CRS name, e.g. "WGS 84 / UTM zone 33N".
  let n = proj_get_name(c.handle)
  if n == nil:
    return ""
  return $n

proc idAuth*(c: Crs): string =
  ## Returns the identifier authority, e.g. "EPSG", or "" when the CRS has
  ## none (a compound CRS genuinely has no identifier).
  let auth = proj_get_id_auth_name(c.handle, 0)
  if auth == nil:
    return ""
  return $auth

proc idCode*(c: Crs): string =
  ## Returns the identifier code, e.g. "32633", or "" when the CRS has none.
  let code = proj_get_id_code(c.handle, 0)
  if code == nil:
    return ""
  return $code

proc isDeprecated*(c: Crs): bool =
  ## Returns whether PROJ marks this CRS as deprecated.
  return proj_is_deprecated(c.handle) != 0

# Predicates are shallow: they test only this object's own type, so a compound
# CRS is not geographic even though its first component is. Use `subCrs` for
# the recursive answer.
proc isGeographic*(c: Crs): bool =
  ## Returns whether this CRS is itself a geographic (2D or 3D) CRS.
  return c.crsType in {Geographic2DCrs, Geographic3DCrs}

proc isProjected*(c: Crs): bool =
  ## Returns whether this CRS is itself a projected CRS.
  return c.crsType == ProjectedCrs

proc isBound*(c: Crs): bool =
  ## Returns whether this CRS is itself a bound CRS.
  return c.crsType == BoundCrs

proc isCompound*(c: Crs): bool =
  ## Returns whether this CRS is itself a compound CRS.
  return c.crsType == CompoundCrs

proc isEquivalentTo*(a: Crs; b: Crs): bool =
  ## Returns whether the two CRSs are equivalent under PROJ's `Equivalent`
  ## criterion (same meaning, not necessarily same serialization).
  return proj_is_equivalent_to(a.handle, b.handle, Equivalent) != 0

proc subCrs*(c: Crs; index: int): Crs =
  ## Returns the component CRS at `index` (0-based), as an owned `Crs`.
  ##
  ## Raises `CrsError` when the index is out of range.
  let sub = proj_crs_get_sub_crs(c.ctx, c.handle, index.cint)
  if cast[pointer](sub) == nil:
    raise newException(CrsError,
      "proj_crs_get_sub_crs() returned nil — index out of range")
  return Crs(ctx: c.ctx, handle: sub, crsType: proj_get_type(sub))

# ── Outputs ──────────────────────────────────────────────────────────────────
proc toWkt*(c: Crs; wktType = Wkt2_2019): string =
  ## Serializes the CRS to WKT in the given flavor.
  let wkt = proj_as_wkt(c.ctx, c.handle, wktType, nil)
  if wkt == nil:
    return ""
  return $wkt

proc toProjString*(c: Crs; projStringType = Proj5): string =
  ## Serializes the CRS to a proj-string in the given version flavor.
  let s = proj_as_proj_string(c.ctx, c.handle, projStringType, nil)
  if s == nil:
    return ""
  return $s

proc toProjJson*(c: Crs): string =
  ## Serializes the CRS to PROJJSON.
  let json = proj_as_projjson(c.ctx, c.handle, nil)
  if json == nil:
    return ""
  return $json

proc `$`*(c: Crs): string =
  ## Returns the WKT2_2019 representation of the CRS.
  return c.toWkt()
