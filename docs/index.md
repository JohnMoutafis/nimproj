# nimproj

Nim binding for [PROJ](https://proj.org/) — coordinate reference systems,
coordinate transformations, datum shifts, and geodesic computation.

Transform coordinates between CRS, read and write CRS definitions as WKT2,
PROJJSON or PROJ strings, query the EPSG registry, inspect the candidate
coordinate operations between two CRS, and measure distances on an ellipsoid —
from idiomatic Nim, over the same engine GDAL, PostGIS and QGIS use.

!!! warning "v0.1.0 in progress"
    Nothing is published yet. v0.1.0 ships the package scaffolding, the Layer-0
    bindings, `ProjContext` and the version functions. The quick start below is
    the **target** API, delivered in v0.3.0.

## Quick start

```nim
import nimproj

let ctx = initProjContext()                                # one owner, one thread
let t   = ctx.initTransformer("EPSG:4326", "EPSG:32633")   # alwaysXY = true

let c = t.transform(coord(12.5, 41.9))                     # lon, lat
echo c.east, " ", c.north
# 292624.8752543277 4641695.877909009

echo t.inverse(c).lon, " ", t.inverse(c).lat
# 12.499999999999998 41.89999999999999
```

## Read this before the API reference

**Axis order.** `EPSG:4326` is defined latitude-first, and PROJ honours the
definition. nimproj defaults to the opposite — longitude, latitude — because
that is what almost every caller means and a wrong axis order produces a wrong
answer with no error. If you need PROJ's native behaviour, pass
`alwaysXY = false`.

## What this is not

- **Not a re-implementation of projection mathematics.** PROJ is the engine.
- **Not a drop-in pyproj port.** No `Proj` class, and the axis-order default
  differs (deliberately).
- **Not hermetic.** PROJ ≥ 9.0 is a system dependency, never vendored.

## Next

- [Installation](getting-started/installation.md)
- [Support policy](support.md)
- [Development setup](contributing/setup.md)
