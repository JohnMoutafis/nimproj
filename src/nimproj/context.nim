## PROJ context lifecycle wrapper.
## One `ProjContext` per thread. Non-copyable, deterministically destroyed by ORC.
## See also: `docs/getting-started/context-lifecycle.md`.

import ./private/proj_abi
import ./errors

# ── ProjContext type ──────────────────────────────────────────────────────────
type
  ProjContext* = object
    handle*: PROJContextHandle  ## Internal — not part of the stable API. Subject to change.

## Disallows copying of ProjContext
proc `=copy`*(dst: var ProjContext; src: ProjContext) {.error:
  "ProjContext is non-copyable: PROJ contexts are not thread-safe when shared. " &
  "Pass by var, or use move().".}

proc `=destroy`*(ctx: ProjContext) =
  ## Destroys the PROJ context through `proj_context_destroy`, deterministically,
  ## under ORC. A moved-from value has a nil handle, so this is a no-op for it.
  if cast[pointer](ctx.handle) != nil:
    proj_context_destroy(ctx.handle)

# ── Constructor ───────────────────────────────────────────────────────────────
proc initProjContext*(): ProjContext =
  ## Initialises a PROJ context. Use one per thread.
  ##
  ## Raises `ProjInitError` if PROJ returns a nil handle — which means the
  ## library is missing, or a different one than expected was linked.
  let handle = proj_context_create()
  if cast[pointer](handle) == nil:
    raise newException(ProjInitError,
      "proj_context_create() returned nil — is libproj >= 9.0 installed?")
  return ProjContext(handle: handle)

# ── Library information ───────────────────────────────────────────────────────
# `proj_info()` is library-level and needs no context.

proc projVersion*(): string =
  ## Returns the PROJ version number, e.g. "9.7.1".
  return $proj_info().version

proc projVersionString*(): string =
  ## Returns PROJ's full release line, e.g. "Rel. 9.7.1, December 1st, 2025".
  ## For logs and bug reports; it contains `projVersion()`.
  return $proj_info().release

# ── Errors ────────────────────────────────────────────────────────────────────
proc lastError*(ctx: ProjContext): string =
  ## Returns the message for the most recent failure recorded on this context,
  ## or "" when the last operation succeeded. PROJ clears its error code on
  ## success, so this means "the last operation", not "any operation ever".
  let err = proj_context_errno(ctx.handle)
  if err == 0:
    return ""
  return $proj_context_errno_string(ctx.handle, err)
