# Coordinate Reference Systems

A `Crs` is a coordinate reference system: a definition you can inspect,
compare, serialise, and later transform coordinates between.

## Creating a CRS

```nim
import nimproj

let ctx = initProjContext()
let utm = ctx.initCrs("EPSG:32633")
# =destroy runs at the end of the scope and frees the CRS
```

`initCrs` accepts every definition form `proj_create` accepts:

- EPSG codes: `"EPSG:32633"`, `"EPSG:4326"`
- Compound codes: `"EPSG:4326+3855"` (a 2D CRS plus a vertical CRS)
- URNs: `"urn:ogc:def:crs:EPSG::4326"`
- WKT — WKT1 (GDAL, ESRI) and WKT2 (2015, 2019)
- PROJJSON
- PROJ strings: `"+proj=longlat +datum=WGS84 +no_defs"`

Anything PROJ cannot parse raises `CrsError`.

## Identity

```nim
echo utm.name      # "WGS 84 / UTM zone 33N"
echo utm.idAuth    # "EPSG"
echo utm.idCode    # "32633"
```

A CRS that has no identifier reports `""` for `idAuth` and `idCode`. A
**compound** CRS is the common case: `EPSG:4326+3855` has the name
`"WGS 84 + EGM2008 height"` but no identifier of its own — the identifiers
live on its components.

## Predicates are shallow

`isGeographic`, `isProjected`, `isBound`, `isCompound` and `isDeprecated`
answer about **this CRS only**, not about what it is made of:

```nim
let compound = ctx.initCrs("EPSG:4326+3855")
echo compound.isCompound    # true
echo compound.isGeographic  # false — the compound itself is not a geographic CRS
```

This is the pitfall: a compound CRS is not geographic, even though its first
component is. The composed answer costs one `subCrs` call:

```nim
echo compound.subCrs(0).isGeographic  # true — "WGS 84"
echo compound.subCrs(1).name          # "EGM2008 height"
```

`subCrs(index)` returns the component at that index, and raises `CrsError`
when the index is past the last one (PROJ returns a null object for an
out-of-range index). `isEquivalentTo` compares two CRS structurally.

## Output formats

```nim
echo utm.toWkt()          # WKT2_2019 by default; GEOGCRS/PROJCRS/COMPOUNDCRS[…]
echo utm.toProjString()   # "+proj=utm +zone=33 +datum=WGS84 …" (PROJ5 by default)
echo utm.toProjJson()     # PROJJSON
echo utm                  # same as toWkt()
```

`toWkt` takes a `PROJWktType` (`Wkt2_2019` is the default; `Wkt1Gdal`,
`Wkt1Esri` and the others exist), `toProjString` takes a `PROJStringType`.

!!! warning "PROJ-string output drops geoid models"
    The PROJ-string format cannot carry everything a CRS can express. When a
    CRS carries a geoid model — a vertical CRS, or a compound CRS built on
    one — `projinfo -o PROJ` emits `+geoidgrids=` and `+geoid_crs=`, but
    `toProjString()` does not. This is PROJ's C API behaviour, not a gap in
    the wrapper: `proj_as_proj_string` returns the shorter string for the
    same object on every creation path. Use `toWkt()` or `toProjJson()` when
    the full definition matters — those carry the geoid model losslessly.
    Measured against PROJ 9.7.1, 2026-10-13.

## Ownership

A `Crs` owns its PROJ handle. Copying deep-copies through `proj_clone`, and
the destructor frees through `proj_destroy`, so a copied `Crs` is an
independent object, never a double-free waiting to happen:

```nim
let a = ctx.initCrs("EPSG:4326")
let b = a          # a full clone, not a shared handle
```

Passing a `Crs` to a proc is free — read-only parameters copy nothing. Only
an explicit assignment clones.
