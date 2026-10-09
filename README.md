# nimproj

[![CI](https://github.com/JohnMoutafis/nimproj/actions/workflows/ci.yml/badge.svg)](https://github.com/JohnMoutafis/nimproj/actions/workflows/ci.yml)

Nim binding for [PROJ](https://proj.org/) — coordinate reference systems,
coordinate transformations, datum shifts, and geodesic computation.

Transform coordinates between CRS, read and write CRS definitions as WKT2,
PROJJSON, or PROJ strings, query the EPSG registry, inspect the candidate
coordinate operations between two CRS, and measure distances on an ellipsoid —
from idiomatic Nim, over the same engine GDAL, PostGIS and QGIS use.

## Requirements

- Nim ≥ 2.0.0
- PROJ ≥ 9.0 (`libproj`) and its `proj.db`, installed as a system library

See [Installation](docs/getting-started/installation.md) for per-platform
instructions.

## Quick start

Target API — the shape v0.3.0 delivers:

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

Note the default: `initTransformer` takes **longitude, latitude** unless you ask
otherwise, where pyproj defaults to the CRS's own axis order. That difference is
deliberate: a wrong axis order produces a wrong answer with no error, so the
default is the one almost every caller means.

## Documentation

- [Installation](docs/getting-started/installation.md)
- [Context lifecycle](docs/getting-started/context-lifecycle.md) — `initProjContext`, one owner per context, thread safety, `lastError`
- [Error types](docs/patterns/error-types.md) — `ProjError` and its subtypes, and the one case that does not raise
- [Support policy](docs/support.md) — supported PROJ and Nim versions, platforms
- [Contributing](CONTRIBUTING.md) — setup, testing policy, code style, release process
- API reference — generated with `nim doc`, published with the docs site

## Conventions worth knowing

- The `proj.h` and `geodesic.h` bindings live only in
  `src/nimproj/private/`, are never exported, and carry `header` on every
  declaration so the C compiler checks the ABI.
- Projection mathematics is **not** implemented here; PROJ is the engine.

## License

[MIT](LICENSE).
