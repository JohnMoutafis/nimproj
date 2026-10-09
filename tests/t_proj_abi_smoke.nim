import unittest
# Reaches into `private/` deliberately: this file exists to prove the layer
# below the wrapper — linking, the `header` pragma, the struct returned by value
# and the error channel — before any wrapper exists.
import nimproj/private/proj_abi

# ── Library information ───────────────────────────────────────────────────────

suite "PROJ ABI smoke test":
  test "proj_info returns a non-empty runtime version":
    let info = proj_info()
    check info.version.len > 0
    check info.major >= 9
    echo "PROJ ", $info.version, "  (", info.major, ".", info.minor, ".", info.patch, ")"
    echo "release: ", $info.release

  # ── Context lifecycle ───────────────────────────────────────────────────────
  test "context init and destroy":
    let ctx = proj_context_create()
    check cast[pointer](ctx) != nil
    proj_context_destroy(ctx)

  # ── The error channel ───────────────────────────────────────────────────────
  test "a bogus definition fails and reports through the context":
    ## PROJ also logs this itself, on stderr, before this code runs. A failed
    ## `proj_create` returns nil and sets the *context's* error code — the return
    ## value is not the error channel.
    let ctx = proj_context_create()
    let bogus = proj_create(ctx, "not-a-crs")
    check cast[pointer](bogus) == nil

    let err = proj_context_errno(ctx)
    check err != 0

    let message = $proj_context_errno_string(ctx, err)   # copy before ctx dies
    check message.len > 0
    echo "proj_create error: ", message
    proj_context_destroy(ctx)

  test "a valid PROJ string resolves":
    let ctx = proj_context_create()
    let utm = proj_create(ctx, "+proj=utm +zone=33 +ellps=WGS84 +type=crs")
    check cast[pointer](utm) != nil
    proj_context_destroy(ctx)
