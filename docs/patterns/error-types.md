# Error Types

nimproj defines a hierarchy of error types, all inheriting from `ProjError` (which inherits from `CatchableError`):

```nim
ProjError* = object of CatchableError
  errno*: cint                         # PROJ's numeric error code, 0 when there was none
ProjInitError*  = object of ProjError  # a ProjContext could not be created
CrsError*       = object of ProjError  # a CRS definition could not be parsed (v0.2.0)
TransformError* = object of ProjError  # a coordinate transformation failed (v0.3.0)
GeodError*      = object of ProjError  # a geodesic computation failed (v0.7.0)
```

## ProjInitError

Raised when:

- `initProjContext()` cannot create a context — in practice `libproj` is not installed, or a different one than expected is on the path.

```nim
try:
  let ctx = initProjContext()
except ProjInitError as e:
  echo "PROJ init failed: ", e.msg
  # Common cause: libproj >= 9.0 not installed
```

## CrsError, TransformError, GeodError

Declared, and named in the published contract, but **not raised before the version that needs them**: `CrsError` from v0.2.0, `TransformError` from v0.3.0, `GeodError` from v0.7.0. A caller catching `ProjError` is already complete today, and stays complete when the subtypes start arriving.

```nim
try:
  let crs = ctx.initCrs("EPSG:4326")   # v0.2.0
except CrsError as e:
  echo "bad CRS definition: ", e.msg
```

## The one deliberate exception: bulk transforms do not raise

A *scalar* call raises on failure. A *bulk* call — one transform over an array of coordinates — passes `Inf`/`NaN` through per coordinate instead, because `proj_trans_array` has no per-element status channel with which to say *which* coordinate failed. A failed coordinate is a value you check, not an exception you catch.

## Reading PROJ's own message

`lastError()` on a `ProjContext` returns PROJ's message for the most recent failure on that context, or `""` when the last operation succeeded — PROJ clears its error code on success, so it means "the last operation", not "any operation ever". Every raised type carries the numeric code in `errno` when PROJ reported one.

See also [Context lifecycle](../getting-started/context-lifecycle.md) for how a context owns that error state.
