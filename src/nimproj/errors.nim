## Error types for PROJ operations.
## See also: `docs/patterns/error-types.md`.

type
  ProjError* = object of CatchableError
    ## Base error type for PROJ operations.
    errno*: cint  ## PROJ's numeric error code, or 0 when the failure had none.
  ProjInitError* = object of ProjError
    ## Raised when a `ProjContext` cannot be created — in practice, `libproj`
    ## is not installed or a different one than expected is on the path.
  CrsError* = object of ProjError
    ## Raised when a CRS definition cannot be parsed or resolved (from v0.2.0).
  TransformError* = object of ProjError
    ## Raised when a coordinate transformation fails (from v0.3.0).
  GeodError* = object of ProjError
    ## Raised when a geodesic computation fails (from v0.7.0).
